import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/drug_interactions.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/hospital_api.dart';
import '../shared/widgets.dart';
import 'role_scaffold.dart';

enum _DoctorTab { today, queue, tools, messages }

class DoctorShell extends StatefulWidget {
  final Widget? child;

  const DoctorShell({super.key, this.child});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  final _db = DatabaseHelper();
  final _api = HospitalApi();
  int _index = 0;
  Doctor? _doctor;
  List<Patient> _patients = const [];
  List<Medicine> _medicines = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDoctor());
  }

  Future<void> _loadDoctor() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    Doctor? doctor;
    if (user?.id != null) {
      doctor = await _db.getDoctorByUserId(user!.id!);
    }
    doctor ??= (await _api.getDoctors()).firstOrNull;
    final patients = await _db.getAllPatients();
    final medicines = await _db.getAllMedicines();
    if (!mounted) return;
    setState(() {
      _doctor = doctor;
      _patients = patients;
      _medicines = medicines;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = _DoctorTab.values[_index];
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Today',
          ),
          NavigationDestination(icon: Icon(Icons.queue), label: 'Queue'),
          NavigationDestination(
            icon: Icon(Icons.medical_services),
            label: 'Tools',
          ),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
        ],
      ),
    );
  }

  String _titleFor(_DoctorTab tab) {
    switch (tab) {
      case _DoctorTab.today:
        return 'Doctor Schedule';
      case _DoctorTab.queue:
        return 'Doctor Queue';
      case _DoctorTab.tools:
        return 'Doctor Tools';
      case _DoctorTab.messages:
        return 'Messages';
    }
  }

  Widget _bodyFor(_DoctorTab tab) {
    switch (tab) {
      case _DoctorTab.today:
        return _ScheduleTimeline(doctorId: _doctor?.id);
      case _DoctorTab.queue:
        return _DoctorQueueTab(doctorId: _doctor?.id, db: _db);
      case _DoctorTab.tools:
        return _PrescriptionWriterTab(
          db: _db,
          api: _api,
          doctorId: _doctor?.id,
          patients: _patients,
          medicines: _medicines,
        );
      case _DoctorTab.messages:
        return _MessagesTab(doctorId: _doctor?.id);
    }
  }
}

class _PrescriptionWriterTab extends StatefulWidget {
  final DatabaseHelper db;
  final HospitalApi api;
  final int? doctorId;
  final List<Patient> patients;
  final List<Medicine> medicines;

  const _PrescriptionWriterTab({
    required this.db,
    required this.api,
    required this.doctorId,
    required this.patients,
    required this.medicines,
  });

  @override
  State<_PrescriptionWriterTab> createState() => _PrescriptionWriterTabState();
}

class _PrescriptionWriterTabState extends State<_PrescriptionWriterTab> {
  final _patientSearchController = TextEditingController();
  final _diagnosisController = TextEditingController();
  int? _patientId;
  String? _patientName;
  final List<_MedicineRow> _rows = [_MedicineRow()];

  @override
  Widget build(BuildContext context) {
    final interactions = DrugInteractionChecker.findInteractions(
      _rows.map((row) => row.name).where((name) => name.isNotEmpty).toList(),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Prescription Writer'),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _patientName ?? ''),
                optionsBuilder: (_) => widget.patients.map(
                  (patient) => patient.name ?? 'Patient ${patient.id}',
                ),
                onSelected: (value) {
                  final patient = widget.patients
                      .where(
                        (item) => (item.name ?? 'Patient ${item.id}') == value,
                      )
                      .firstOrNull;
                  if (patient != null) {
                    setState(() {
                      _patientId = patient.id;
                      _patientName = patient.name;
                      _patientSearchController.text = _patientName ?? '';
                    });
                  }
                },
                fieldViewBuilder: (_, controller, focusNode, onSubmitted) {
                  _patientSearchController.text = _patientName ?? '';
                  return TextField(
                    controller: _patientSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Patient name',
                    ),
                  );
                },
              ),
              TextField(
                controller: _diagnosisController,
                decoration: const InputDecoration(labelText: 'Diagnosis'),
              ),
              ..._rows.asMap().entries.map(
                (entry) => _MedicineEditor(
                  key: ValueKey(entry.key),
                  row: entry.value,
                  medicines: widget.medicines
                      .map(
                        (medicine) =>
                            medicine.name ?? 'Medicine ${medicine.id}',
                      )
                      .toList(),
                  onRemove: _rows.length == 1
                      ? null
                      : () => setState(() => _rows.removeAt(entry.key)),
                ),
              ),
              if (interactions.isNotEmpty)
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      interactions.join('\n'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _rows.add(_MedicineRow())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Row'),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.doctorId == null || _patientId == null
                    ? null
                    : _savePrescription,
                icon: const Icon(Icons.save),
                label: const Text('Save Prescription'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _savePrescription() async {
    if (widget.doctorId == null || _patientId == null) return;
    final rows = _rows.map((row) => row.toMap()).toList();
    final now = DateTime.now().toIso8601String();
    await widget.db.insertPrescription(
      Prescription(
        appointmentId: null,
        patientId: _patientId,
        medicines: jsonEncode(rows),
        notes: _diagnosisController.text.trim(),
        isDispensed: false,
        createdAt: now,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Prescription saved.')));
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _patientSearchController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}

class _MedicineEditor extends StatelessWidget {
  final _MedicineRow row;
  final List<String> medicines;
  final VoidCallback? onRemove;

  const _MedicineEditor({
    super.key,
    required this.row,
    required this.medicines,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (_) => medicines,
              onSelected: (value) => row.name = value,
              fieldViewBuilder: (_, controller, focusNode, onSubmitted) =>
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Medicine'),
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: row.frequency,
                    items: const ['OD', 'BD', 'TDS', 'QID']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => row.frequency = value ?? 'OD',
                    decoration: const InputDecoration(labelText: 'Frequency'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.durationController,
                    decoration: const InputDecoration(labelText: 'Duration'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                    ),
                  ),
                ),
              ],
            ),
            if (onRemove != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MedicineRow {
  String name = '';
  String frequency = 'OD';
  final dosageController = TextEditingController();
  final durationController = TextEditingController();
  final instructionsController = TextEditingController();

  Map<String, dynamic> toMap() => {
    'name': name,
    'dosage': dosageController.text,
    'frequency': frequency,
    'duration': durationController.text,
    'instructions': instructionsController.text,
  };

  void dispose() {
    dosageController.dispose();
    durationController.dispose();
    instructionsController.dispose();
  }
}

Future<void> showLabOrderDialog({
  required BuildContext context,
  required int? doctorId,
  required int? patientId,
  required DatabaseHelper db,
}) async {
  if (doctorId == null || patientId == null) return;
  final selected = <String>{'CBC'};
  var priority = 'Routine';
  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Order Lab Test'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...[
                  'CBC',
                  'Lipid Profile',
                  'Blood Sugar',
                  'X-Ray',
                  'ECG',
                  'MRI',
                  'Urine Culture',
                ].map(
                  (test) => CheckboxListTile(
                    value: selected.contains(test),
                    title: Text(test),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        selected.add(test);
                      } else {
                        selected.remove(test);
                      }
                    }),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  items: const ['Routine', 'Urgent', 'Stat']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => priority = value ?? 'Routine'),
                  decoration: const InputDecoration(labelText: 'Priority'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await db.insertLabOrder(
                    LabOrder(
                      doctorId: doctorId,
                      patientId: patientId,
                      tests: selected.toList(),
                      priority: priority,
                      createdAt: DateTime.now().toIso8601String(),
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ScheduleTimeline extends StatefulWidget {
  final int? doctorId;

  const _ScheduleTimeline({this.doctorId});

  @override
  State<_ScheduleTimeline> createState() => _ScheduleTimelineState();
}

class _ScheduleTimelineState extends State<_ScheduleTimeline> {
  final _db = DatabaseHelper();
  final _api = HospitalApi();
  List<Appointment> _appointments = const [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final today = _today();
    final appointments = (await _api.getAppointments())
        .where(
          (item) =>
              item.doctorId == widget.doctorId &&
              item.date?.contains(today) == true,
        )
        .toList();
    if (!mounted) return;
    setState(() => _appointments = appointments);
  }

  @override
  Widget build(BuildContext context) {
    final slots = const [
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '15:00',
      '15:30',
      '16:00',
    ];
    return AppCard(
      child: ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onReorder: (_, previous) {},
        children: List.generate(slots.length, (index) {
          final slot = slots[index];
          final appointment = _appointments
              .where((item) => item.time == slot)
              .firstOrNull;
          return _ScheduleSlot(
            key: ValueKey(slot),
            slot: slot,
            appointment: appointment,
            onEmptyTap: () => _showSlotDialog(slot),
          );
        }),
      ),
    );
  }

  Future<void> _showSlotDialog(String slot) async {
    final today = _today();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Slot $slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _db.insertAppointment(
                    Appointment(
                      doctorId: widget.doctorId,
                      date: today,
                      time: slot,
                      status: 'Blocked',
                      symptoms: 'Blocked time',
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadAppointments();
                },
                icon: const Icon(Icons.block),
                label: const Text('Block Time'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _db.insertAppointment(
                    Appointment(
                      doctorId: widget.doctorId,
                      date: today,
                      time: slot,
                      status: 'Walk-in',
                      symptoms: 'Walk-in patient',
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadAppointments();
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Walk-in'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _ScheduleSlot extends StatelessWidget {
  final String slot;
  final Appointment? appointment;
  final VoidCallback onEmptyTap;

  const _ScheduleSlot({
    super.key,
    required this.slot,
    this.appointment,
    required this.onEmptyTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: 0,
      child: ListTile(
        onTap: appointment == null ? onEmptyTap : null,
        leading: CircleAvatar(child: Text(slot)),
        title: Text(appointment?.status ?? 'Empty'),
        subtitle: Text(
          appointment == null ? 'Tap to block or add walk-in' : 'In-person',
        ),
        trailing: appointment?.isOnline == true
            ? const Icon(Icons.videocam)
            : null,
      ),
    );
  }
}

class _DoctorQueueTab extends StatelessWidget {
  final DatabaseHelper db;
  final int? doctorId;

  const _DoctorQueueTab({required this.db, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: db.getAllAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments =
            (snapshot.data ?? [])
                .where((item) => item.doctorId == doctorId)
                .toList()
              ..sort((a, b) => _compareAppointmentTime(a, b));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Today Queue'),
                  if (appointments.isEmpty)
                    const Text('No appointments for this doctor.')
                  else
                    ...appointments.map(
                      (appointment) => ListTile(
                        leading: AppAvatar(
                          label: appointment.isOnline ? 'VC' : 'AP',
                          icon: appointment.isOnline
                              ? Icons.videocam
                              : Icons.calendar_today,
                        ),
                        title: Text('Appointment ${appointment.id}'),
                        subtitle: Text(
                          '${appointment.date ?? ''} ${appointment.time ?? ''} • ${appointment.status ?? ''}',
                        ),
                        trailing: appointment.isOnline
                            ? const Icon(Icons.videocam)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

int _compareAppointmentTime(Appointment a, Appointment b) {
  final aDate = _dateOnly(a.date);
  final bDate = _dateOnly(b.date);
  final dateCompare = aDate.compareTo(bDate);
  if (dateCompare != 0) return dateCompare;
  return (a.time ?? '').compareTo(b.time ?? '');
}

DateTime _dateOnly(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  return parsed ?? DateTime(1970);
}

class _MessagesTab extends StatefulWidget {
  final int? doctorId;

  const _MessagesTab({this.doctorId});

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  final _db = DatabaseHelper();
  final _api = HospitalApi();
  List<Appointment> _followUps = const [];

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  Future<void> _loadFollowUps() async {
    final now = DateTime.now();
    final start =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final end = now.add(const Duration(days: 7));
    final endString =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final appointments = (await _api.getAppointments()).where((item) {
      final date = item.followUpDate ?? '';
      return item.doctorId == widget.doctorId &&
          !item.reminderSent &&
          date.compareTo(start) >= 0 &&
          date.compareTo(endString) <= 0;
    }).toList();
    if (!mounted) return;
    setState(() => _followUps = appointments);
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
              const SectionHeader(title: 'Follow-Ups'),
              if (_followUps.isEmpty)
                const Text('No follow-ups due in the next 7 days.')
              else
                ..._followUps.map(
                  (appointment) => ListTile(
                    title: Text('Follow-up ${appointment.id}'),
                    subtitle: Text('Due ${appointment.followUpDate ?? ''}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await _db.updateAppointmentFollowUp(
                          id: appointment.id!,
                          reminderSent: true,
                        );
                        _loadFollowUps();
                      },
                      child: const Text('Send Reminder'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const AppCard(child: Text('Messages inbox placeholder')),
      ],
    );
  }
}

class TelemedicineCallScreen extends StatefulWidget {
  final QueueEntry queueEntry;

  const TelemedicineCallScreen({super.key, required this.queueEntry});

  @override
  State<TelemedicineCallScreen> createState() => _TelemedicineCallScreenState();
}

class _TelemedicineCallScreenState extends State<TelemedicineCallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildRoleAppBar('Telemedicine Call', context),
      body: Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam, size: 72),
              const SizedBox(height: 16),
              Text(
                'Video call placeholder for token ${widget.queueEntry.tokenNumber}',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('End Call'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
