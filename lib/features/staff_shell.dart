import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/hospital_api.dart';
import '../shared/widgets.dart';

enum _StaffTab { tasks, beds, shift, queue }

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  final _db = DatabaseHelper();
  final _api = HospitalApi();
  int _index = 0;
  int? _staffId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStaffId());
  }

  Future<void> _loadStaffId() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!mounted) return;
    setState(() => _staffId = auth.currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {
    final tab = _StaffTab.values[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(tab)),
        actions: [
          const AppSettingsActions(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return TextButton.icon(
                onPressed: () {
                  auth.logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _bodyFor(tab)),
        ],
      ),
      floatingActionButton: tab == _StaffTab.tasks
          ? FloatingActionButton.extended(
              onPressed: () => _recordVitals(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.monitor_heart),
              label: const Text('Record Vitals'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.hotel), label: 'Beds'),
          NavigationDestination(
            icon: Icon(Icons.history_toggle_off),
            label: 'Shift',
          ),
          NavigationDestination(icon: Icon(Icons.queue), label: 'Queue'),
        ],
      ),
    );
  }

  String _titleFor(_StaffTab tab) {
    switch (tab) {
      case _StaffTab.tasks:
        return 'Staff Tasks';
      case _StaffTab.beds:
        return 'Bed Management';
      case _StaffTab.shift:
        return 'Shift Handover';
      case _StaffTab.queue:
        return 'Staff Queue';
    }
  }

  Widget _bodyFor(_StaffTab tab) {
    switch (tab) {
      case _StaffTab.tasks:
        return _TasksTab(staffId: _staffId, onRefresh: _recordVitals);
      case _StaffTab.beds:
        return _BedsTab();
      case _StaffTab.shift:
        return _ShiftTab(staffId: _staffId);
      case _StaffTab.queue:
        return _FutureList<QueueEntry>(
          title: 'Queue',
          future: () => _api.getQueueEntries(),
          empty: 'No queue entries.',
          tile: (entry) => ListTile(
            leading: AppAvatar(label: 'T${entry.tokenNumber}'),
            title: Text('Token ${entry.tokenNumber}'),
            subtitle: Text(entry.status ?? ''),
          ),
        );
    }
  }

  Future<void> _recordVitals() async {
    final assignments = _staffId == null
        ? <StaffAssignment>[]
        : await _db.getStaffAssignments(staffId: _staffId!);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (_) => _RecordVitalsSheet(
        assignments: assignments,
        staffId: _staffId,
        db: _db,
      ),
    );
  }
}

class _TasksTab extends StatefulWidget {
  final int? staffId;
  final VoidCallback onRefresh;

  const _TasksTab({this.staffId, required this.onRefresh});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final _db = DatabaseHelper();
  List<StaffAssignment> _assignments = const [];
  List<StaffTask> _tasks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final staffId = widget.staffId;
    final assignments = staffId == null
        ? <StaffAssignment>[]
        : await _db.getStaffAssignments(staffId: staffId);
    final tasks = staffId == null
        ? <StaffTask>[]
        : (await _db.getAllStaffTasks())
              .where((task) => task.assignedTo == staffId)
              .toList();
    if (!mounted) return;
    setState(() {
      _assignments = assignments;
      _tasks = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'My Patients'),
              if (_assignments.isEmpty)
                const Text('No patients assigned for this shift.')
              else
                ..._assignments.map(
                  (assignment) => _PatientAssignmentCard(
                    assignment: assignment,
                    onTap: () => _showPatientQuickView(assignment),
                  ),
                ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Tasks Due'),
              if (_tasks.isEmpty)
                const Text('No pending tasks.')
              else
                ..._tasks.map(
                  (task) => ListTile(
                    leading: const AppAvatar(label: 'T', icon: Icons.task_alt),
                    title: Text(task.title ?? 'Task ${task.id}'),
                    subtitle: Text(task.description ?? ''),
                    trailing: Chip(label: Text(task.status ?? 'Pending')),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPatientQuickView(StaffAssignment assignment) async {
    final patient = (await _db.getAllPatients())
        .where((item) => item.id == assignment.patientId)
        .firstOrNull;
    final vitals = await _db.getVitals(patientId: assignment.patientId);
    final notes = await _db.getDoctorNotes(patientId: assignment.patientId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(patient?.name ?? 'Patient ${assignment.patientId}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Bed: ${assignment.bedNumber ?? '-'} • Shift: ${assignment.shift ?? '-'}',
                ),
                const Divider(),
                const Text('Last Vitals'),
                ...vitals
                    .take(1)
                    .map(
                      (vital) => Text(
                        'BP ${vital.bpSys}/${vital.bpDia} • SpO2 ${vital.spo2} • Temp ${vital.temp} • Pulse ${vital.pulse} • ${vital.timestamp}',
                      ),
                    ),
                const Divider(),
                const Text('Doctor Notes'),
                ...notes.map((note) => Text('• ${note.note}')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _PatientAssignmentCard extends StatelessWidget {
  final StaffAssignment assignment;
  final VoidCallback onTap;

  const _PatientAssignmentCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StaffVital>>(
      future: DatabaseHelper().getVitals(patientId: assignment.patientId),
      builder: (context, snapshot) {
        final vital = snapshot.data?.firstOrNull;
        return FutureBuilder<List<Patient>>(
          future: DatabaseHelper().getAllPatients(),
          builder: (context, patientSnapshot) {
            final patient = patientSnapshot.data
                ?.where((item) => item.id == assignment.patientId)
                .firstOrNull;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: onTap,
                leading: AppAvatar(label: patient?.name ?? 'P'),
                title: Text(patient?.name ?? 'Patient ${assignment.patientId}'),
                subtitle: Text(
                  'Bed ${assignment.bedNumber ?? '-'} • Age ${patient?.age?.toString() ?? '-'} • Last vitals ${vital?.timestamp ?? '-'}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecordVitalsSheet extends StatefulWidget {
  final List<StaffAssignment> assignments;
  final int? staffId;
  final DatabaseHelper db;

  const _RecordVitalsSheet({
    required this.assignments,
    this.staffId,
    required this.db,
  });

  @override
  State<_RecordVitalsSheet> createState() => _RecordVitalsSheetState();
}

class _RecordVitalsSheetState extends State<_RecordVitalsSheet> {
  final _bpSys = TextEditingController();
  final _bpDia = TextEditingController();
  final _spo2 = TextEditingController();
  final _temp = TextEditingController();
  final _pulse = TextEditingController();
  final _weight = TextEditingController();
  StaffAssignment? _assignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Record Vitals'),
          DropdownButtonFormField<StaffAssignment>(
            initialValue: _assignment,
            hint: const Text('Select assigned patient'),
            items: widget.assignments.map((assignment) {
              return DropdownMenuItem(
                value: assignment,
                child: Text(
                  'Bed ${assignment.bedNumber} • Patient ${assignment.patientId}',
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _assignment = value),
          ),
          _numberField(_bpSys, 'BP Systolic'),
          _numberField(_bpDia, 'BP Diastolic'),
          _numberField(_spo2, 'SpO2'),
          _numberField(_temp, 'Temperature'),
          _numberField(_pulse, 'Pulse'),
          _numberField(_weight, 'Weight'),
          ElevatedButton(onPressed: _save, child: const Text('Save Vitals')),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _save() async {
    final assignment = _assignment;
    if (assignment == null || widget.staffId == null) return;
    final bpSys = int.tryParse(_bpSys.text);
    final bpDia = int.tryParse(_bpDia.text);
    final spo2 = int.tryParse(_spo2.text);
    final temp = double.tryParse(_temp.text);
    final pulse = int.tryParse(_pulse.text);
    final weight = double.tryParse(_weight.text);
    if (bpSys == null ||
        bpDia == null ||
        spo2 == null ||
        temp == null ||
        pulse == null ||
        weight == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter all vitals.')));
      return;
    }
    if (!_inRange(bpSys, 60, 200) ||
        !_inRange(bpDia, 60, 200) ||
        !_inRange(spo2, 70, 100) ||
        !_inRange(temp, 34, 42) ||
        !_inRange(pulse, 30, 250)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vital value out of allowed range.')),
      );
      return;
    }
    final timestamp = DateTime.now().toIso8601String();
    await widget.db.insertVital(
      StaffVital(
        patientId: assignment.patientId,
        recordedBy: widget.staffId!,
        timestamp: timestamp,
        bpSys: bpSys,
        bpDia: bpDia,
        spo2: spo2,
        temp: temp,
        pulse: pulse,
        weight: weight,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Vitals saved at $timestamp')));
  }

  bool _inRange(num value, num min, num max) => value >= min && value <= max;

  @override
  void dispose() {
    _bpSys.dispose();
    _bpDia.dispose();
    _spo2.dispose();
    _temp.dispose();
    _pulse.dispose();
    _weight.dispose();
    super.dispose();
  }
}

class _BedsTab extends StatefulWidget {
  const _BedsTab();

  @override
  State<_BedsTab> createState() => _BedsTabState();
}

class _BedsTabState extends State<_BedsTab> {
  final _db = DatabaseHelper();
  List<Bed> _beds = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final beds = await _db.getAllBeds();
    if (!mounted) return;
    setState(() => _beds = beds);
  }

  @override
  Widget build(BuildContext context) {
    final wards = <int, List<Bed>>{};
    for (final bed in _beds) {
      wards.putIfAbsent(bed.wardId ?? 0, () => []).add(bed);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: wards.entries
          .map(
            (entry) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Ward ${entry.key}'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: entry.value.length,
                    itemBuilder: (_, index) {
                      final bed = entry.value[index];
                      return _BedSlot(
                        bed: bed,
                        onTap: () => _showBedDialog(bed),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _showBedDialog(Bed bed) async {
    final patientNameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bed ${bed.bedNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patientNameController,
                decoration: const InputDecoration(labelText: 'Patient name'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _db.updateBedStatus(id: bed.id!, status: 'Occupied');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _load();
                },
                icon: const Icon(Icons.bed, color: Colors.red),
                label: const Text('Mark Occupied'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _db.updateBedStatus(id: bed.id!, status: 'Cleaning');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _load();
                },
                icon: const Icon(Icons.cleaning_services, color: Colors.amber),
                label: const Text('Mark for Cleaning'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _db.updateBedStatus(id: bed.id!, status: 'Available');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _load();
                },
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: const Text('Mark Available'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final now = DateTime.now().toIso8601String();
                  await _db.insertDischargeRecord(
                    DischargeRecord(
                      patientId: bed.patientId ?? 0,
                      bedId: bed.id!,
                      bedNumber: bed.bedNumber ?? '',
                      dischargedAt: now,
                    ),
                  );
                  await _db.updateBedStatus(id: bed.id!, status: 'Available');
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _load();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Discharge Patient'),
              ),
            ],
          ),
        );
      },
    );
    patientNameController.dispose();
  }
}

class _BedSlot extends StatelessWidget {
  final Bed bed;
  final VoidCallback onTap;

  const _BedSlot({required this.bed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = bed.status == 'Available'
        ? Colors.green
        : bed.status == 'Cleaning'
        ? Colors.amber
        : Colors.red;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withValues(alpha: 0.25),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hotel, color: color),
              Text(bed.bedNumber ?? ''),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftTab extends StatefulWidget {
  final int? staffId;

  const _ShiftTab({this.staffId});

  @override
  State<_ShiftTab> createState() => _ShiftTabState();
}

class _ShiftTabState extends State<_ShiftTab> {
  final _db = DatabaseHelper();
  final _handoverController = TextEditingController();
  List<StaffAttendance> _attendance = const [];
  List<HandoverNote> _notes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final staffId = widget.staffId;
    final attendance = staffId == null
        ? <StaffAttendance>[]
        : await _db.getAttendance(staffId: staffId);
    final notes = staffId == null
        ? <HandoverNote>[]
        : await _db.getHandoverNotes(staffId: staffId);
    if (!mounted) return;
    setState(() {
      _attendance = attendance;
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Attendance & Leave'),
              Text('Clock-in: ${_attendance.firstOrNull?.clockIn ?? '-'}'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _attendance.isEmpty
                    ? _clockIn
                    : () => _clockOut(_attendance.first),
                icon: const Icon(Icons.punch_clock),
                label: Text(_attendance.isEmpty ? 'Clock In' : 'Clock Out'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _applyLeave,
                icon: const Icon(Icons.beach_access),
                label: const Text('Apply Leave'),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Handover Notes'),
              TextField(
                controller: _handoverController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Shift summary'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _submitHandover,
                icon: const Icon(Icons.send),
                label: const Text('Submit Handover'),
              ),
              ..._notes.map(
                (note) => ListTile(
                  leading: const AppAvatar(label: 'H'),
                  title: Text('Shift ${note.shift ?? '-'}'),
                  subtitle: Text('${note.createdAt} • ${note.summary}'),
                  trailing: note.shiftComplete
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              ),
            ],
          ),
        ),
        _TeamChat(staffId: widget.staffId),
      ],
    );
  }

  Future<void> _clockIn() async {
    final staffId = widget.staffId;
    if (staffId == null) return;
    await _db.insertAttendance(
      StaffAttendance(
        staffId: staffId,
        clockIn: DateTime.now().toIso8601String(),
      ),
    );
    _load();
  }

  Future<void> _clockOut(StaffAttendance attendance) async {
    await _db.updateAttendanceClockOut(
      attendance.id!,
      DateTime.now().toIso8601String(),
    );
    _load();
  }

  Future<void> _applyLeave() async {
    final typeController = TextEditingController(text: 'Casual');
    final reasonController = TextEditingController();
    DateTime? start;
    DateTime? end;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Apply Leave'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: typeController.text,
                    items: const ['Sick', 'Casual', 'Annual']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => typeController.text = value ?? 'Casual'),
                  ),
                  ListTile(
                    title: Text(start == null ? 'Start date' : 'Start: $start'),
                    trailing: IconButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) setState(() => start = picked);
                      },
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  ListTile(
                    title: Text(end == null ? 'End date' : 'End: $end'),
                    trailing: IconButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: start ?? DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) setState(() => end = picked);
                      },
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Reason'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    if (widget.staffId == null || start == null || end == null) return;
    await _db.insertLeaveRequest(
      LeaveRequest(
        staffId: widget.staffId!,
        leaveType: typeController.text,
        startDate: _formatDate(start!),
        endDate: _formatDate(end!),
        reason: reasonController.text,
        appliedAt: DateTime.now().toIso8601String(),
      ),
    );
    typeController.dispose();
    reasonController.dispose();
  }

  Future<void> _submitHandover() async {
    final staffId = widget.staffId;
    if (staffId == null || _handoverController.text.trim().isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _db.insertHandoverNote(
      HandoverNote(
        staffId: staffId,
        shift: 'Current',
        summary: _handoverController.text.trim(),
        createdAt: now,
        shiftComplete: true,
      ),
    );
    if (_attendance.firstOrNull != null) {
      await _db.updateAttendanceClockOut(_attendance.first.id!, now);
    }
    _handoverController.clear();
    _load();
  }

  @override
  void dispose() {
    _handoverController.dispose();
    super.dispose();
  }
}

class _TeamChat extends StatefulWidget {
  final int? staffId;

  const _TeamChat({this.staffId});

  @override
  State<_TeamChat> createState() => _TeamChatState();
}

class _TeamChatState extends State<_TeamChat> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Team Chat'),
          ...['All Staff', 'Cardiology', 'Emergency', 'ICU'].map(
            (channel) => ListTile(
              leading: const AppAvatar(label: '#'),
              title: Text(channel),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ChatChannelScreen(
                    channel: channel,
                    staffId: widget.staffId,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatChannelScreen extends StatefulWidget {
  final String channel;
  final int? staffId;

  const _ChatChannelScreen({required this.channel, this.staffId});

  @override
  State<_ChatChannelScreen> createState() => _ChatChannelScreenState();
}

class _ChatChannelScreenState extends State<_ChatChannelScreen> {
  final _db = DatabaseHelper();
  final _controller = TextEditingController();
  List<InternalMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final messages = await _db.getInternalMessages(channel: widget.channel);
    if (!mounted) return;
    setState(() => _messages = messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.channel)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: _messages.map(_messageTile).toList(),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageTile(InternalMessage message) {
    return ListTile(
      leading: CircleAvatar(child: Text(message.isRead ? '✓' : '•')),
      title: Text('Staff ${message.senderId}'),
      subtitle: Text('${message.timestamp}\n${message.text}'),
    );
  }

  Future<void> _send() async {
    final staffId = widget.staffId;
    if (staffId == null || _controller.text.trim().isEmpty) return;
    await _db.insertInternalMessage(
      InternalMessage(
        channel: widget.channel,
        senderId: staffId,
        text: _controller.text.trim(),
        timestamp: DateTime.now().toIso8601String(),
      ),
    );
    _controller.clear();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _FutureList<T> extends StatelessWidget {
  final String title;
  final Future<List<T>> Function() future;
  final String empty;
  final Widget Function(T item) tile;

  const _FutureList({
    required this.title,
    required this.future,
    required this.empty,
    required this.tile,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: FutureBuilder<List<T>>(
        future: future(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Unable to load $title.');
          }
          final items = snapshot.data ?? <T>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: title),
              if (items.isEmpty)
                Text(empty)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, previous) => const Divider(height: 1),
                  itemBuilder: (_, index) => tile(items[index]),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
