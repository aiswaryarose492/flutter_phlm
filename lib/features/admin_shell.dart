import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../shared/widgets.dart';

enum _AdminTab { overview, manage, fleet, audit }

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _db = DatabaseHelper();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tab = _AdminTab.values[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(tab)),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Overview'),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts),
            label: 'Manage',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital),
            label: 'Fleet',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Audit'),
        ],
      ),
    );
  }

  String _titleFor(_AdminTab tab) {
    switch (tab) {
      case _AdminTab.overview:
        return 'Admin Overview';
      case _AdminTab.manage:
        return 'Management';
      case _AdminTab.fleet:
        return 'Ambulance Fleet';
      case _AdminTab.audit:
        return 'User Audit';
    }
  }

  Widget _bodyFor(_AdminTab tab) {
    switch (tab) {
      case _AdminTab.overview:
        return _OverviewTab(db: _db, actorId: _actorId);
      case _AdminTab.manage:
        return _ManageTab(db: _db, actorId: _actorId);
      case _AdminTab.fleet:
        return _FleetTab(db: _db, actorId: _actorId);
      case _AdminTab.audit:
        return _AuditTab(db: _db, actorId: _actorId);
    }
  }

  int? get _actorId =>
      Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
}

class _OverviewTab extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _OverviewTab({required this.db, this.actorId});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  DateTime? _start;
  DateTime? _end;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AnalyticsCards(db: widget.db),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Reports'),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _start = DateTime.now().subtract(const Duration(days: 7));
                      _end = DateTime.now();
                    }),
                    child: const Text('7 Days'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _start = DateTime.now().subtract(
                        const Duration(days: 30),
                      );
                      _end = DateTime.now();
                    }),
                    child: const Text('30 Days'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _pickRange,
                    child: const Text('Custom'),
                  ),
                ],
              ),
              _AppointmentReport(
                db: widget.db,
                actorId: widget.actorId,
                start: _start,
                end: _end,
              ),
            ],
          ),
        ),
        AppCard(child: _PeakHoursChart(db: widget.db)),
      ],
    );
  }

  Future<void> _pickRange() async {
    final start = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (start == null) return;
    final end = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (end != null) {
      setState(() {
        _start = start;
        _end = end;
      });
    }
  }
}

class _AnalyticsCards extends StatelessWidget {
  final DatabaseHelper db;

  const _AnalyticsCards({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppCard(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? {};
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            DashboardStatCard(
              title: 'Appointments',
              value: data['appointments'].toString(),
              icon: Icons.calendar_today,
              color: Colors.blue,
              sparkline: data['appointmentTrend'] as List<int>,
            ),
            DashboardStatCard(
              title: 'Revenue',
              value: '₹${data['revenue'].toStringAsFixed(0)}',
              icon: Icons.attach_money,
              color: Colors.green,
              sparkline: data['revenueTrend'] as List<int>,
            ),
            DashboardStatCard(
              title: 'Doctors',
              value: data['doctors'].toString(),
              icon: Icons.medical_services,
              color: Colors.purple,
              sparkline: data['doctorTrend'] as List<int>,
            ),
            DashboardStatCard(
              title: 'Beds',
              value: data['beds'].toString(),
              icon: Icons.hotel,
              color: Colors.orange,
              sparkline: data['bedTrend'] as List<int>,
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    final appointments = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM appointments',
    );
    final revenue = await db.rawQuery(
      'SELECT COALESCE(SUM(appointment_fees), 0) AS revenue FROM appointments',
    );
    final doctors = await db.rawQuery('SELECT COUNT(*) AS count FROM doctors');
    final beds = await db.rawQuery('SELECT COUNT(*) AS count FROM beds');
    final appointmentTrend = await _dailyCounts('appointments');
    final revenueTrend = await _dailyTotals('appointments', 'appointment_fees');
    return {
      'appointments': appointments.first['count'] as int? ?? 0,
      'revenue': (revenue.first['revenue'] as num?)?.toDouble() ?? 0.0,
      'doctors': doctors.first['count'] as int? ?? 0,
      'beds': beds.first['count'] as int? ?? 0,
      'appointmentTrend': appointmentTrend,
      'revenueTrend': revenueTrend,
      'doctorTrend': const [1, 1, 2, 2, 2, 3, 3],
      'bedTrend': const [10, 10, 11, 10, 12, 12, 12],
    };
  }

  Future<List<int>> _dailyCounts(String table) async {
    final rows = await db.rawQuery(
      'SELECT date(date) AS date, COUNT(*) AS count FROM $table GROUP BY date(date) ORDER BY date(date) DESC LIMIT 7',
    );
    final values = List<int>.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      final formatted = _formatDate(date);
      return rows
          .where((row) => row['date'] == formatted)
          .fold<int>(0, (sum, row) => sum + (row['count'] as int? ?? 0));
    });
    return values;
  }

  Future<List<int>> _dailyTotals(String table, String column) async {
    final rows = await db.rawQuery(
      'SELECT date(date) AS date, COALESCE(SUM($column), 0) AS total FROM $table GROUP BY date(date) ORDER BY date(date) DESC LIMIT 7',
    );
    final values = List<int>.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      final formatted = _formatDate(date);
      return rows
          .where((row) => row['date'] == formatted)
          .fold<int>(
            0,
            (sum, row) => sum + (((row['total'] as num?)?.toInt()) ?? 0),
          );
    });
    return values;
  }
}

class _AppointmentReport extends StatelessWidget {
  final DatabaseHelper db;
  final int? actorId;
  final DateTime? start;
  final DateTime? end;

  const _AppointmentReport({
    required this.db,
    this.actorId,
    this.start,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    final selectedStart = start;
    final selectedEnd = end;
    final startDate = selectedStart == null ? null : _formatDate(selectedStart);
    final endDate = selectedEnd == null ? null : _formatDate(selectedEnd);
    final where = startDate != null && endDate != null
        ? 'WHERE date(date) BETWEEN date(?) AND date(?)'
        : '';
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.rawQuery(
        'SELECT status, COUNT(*) AS count FROM appointments $where GROUP BY status',
        startDate != null && endDate != null ? [startDate, endDate] : const [],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final data = snapshot.data ?? [];
        final total = data.fold<int>(
          0,
          (sum, row) => sum + (row['count'] as int? ?? 0),
        );
        final completed = data
            .where((row) => row['status'] == 'Completed')
            .fold<int>(0, (sum, row) => sum + (row['count'] as int? ?? 0));
        final cancelled = data
            .where((row) => row['status'] == 'Cancelled')
            .fold<int>(0, (sum, row) => sum + (row['count'] as int? ?? 0));
        final noShow = data
            .where((row) => row['status'] == 'No Show')
            .fold<int>(0, (sum, row) => sum + (row['count'] as int? ?? 0));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MiniBarChart(
              values: [total, completed, cancelled, noShow],
              labels: const ['Total', 'Completed', 'Cancelled', 'No-show'],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _exportCsv(context, db, actorId),
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
            ),
            const SizedBox(height: 12),
            _RevenueByDepartment(db: db),
          ],
        );
      },
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    DatabaseHelper db,
    int? actorId,
  ) async {
    try {
      final rows = await db.rawQuery(
        'SELECT id, doctor_id, patient_id, date, time, status FROM appointments',
      );
      final csv = rows
          .map(
            (row) => row.values
                .map((value) => '"${value.toString().replaceAll('"', '""')}"')
                .join(','),
          )
          .join('\n');
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'appointments_report.csv'));
      await file.writeAsString(csv);
      await db.insertAuditLog(
        who: actorId,
        action: 'EXPORT_APPOINTMENT_REPORT',
        targetUserId: actorId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export failed.')));
    }
  }
}

class _RevenueByDepartment extends StatelessWidget {
  final DatabaseHelper db;

  const _RevenueByDepartment({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.rawQuery(
        'SELECT d.department, SUM(a.appointment_fees) AS revenue FROM doctors d LEFT JOIN appointments a ON a.doctor_id = d.id GROUP BY d.department',
      ),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Revenue by Department'),
            ...rows.map((row) {
              final revenue = (row['revenue'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(row['department'] ?? '-')),
                    Expanded(
                      child: LinearProgressIndicator(value: revenue / 10000),
                    ),
                    Text(revenue.toStringAsFixed(0)),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _ManageTab extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _ManageTab({required this.db, this.actorId});

  @override
  State<_ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<_ManageTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DoctorsSection(db: widget.db, actorId: widget.actorId),
        _DepartmentsSection(db: widget.db, actorId: widget.actorId),
        _StaffSection(db: widget.db, actorId: widget.actorId),
        _LeaveApprovalSection(db: widget.db, actorId: widget.actorId),
      ],
    );
  }
}

class _DoctorsSection extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _DoctorsSection({required this.db, this.actorId});

  @override
  State<_DoctorsSection> createState() => _DoctorsSectionState();
}

class _DoctorsSectionState extends State<_DoctorsSection> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Doctors',
            action: ElevatedButton(
              onPressed: () => _showAddDoctor(context),
              child: const Text('Add Doctor'),
            ),
          ),
          FutureBuilder<List<Doctor>>(
            future: widget.db.getAllDoctors(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final doctors = snapshot.data ?? [];
              return Column(
                children: doctors
                    .map(
                      (doctor) => _DoctorCard(
                        db: widget.db,
                        actorId: widget.actorId,
                        doctor: doctor,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDoctor(BuildContext context) async {
    final name = TextEditingController();
    final specialty = TextEditingController();
    final department = TextEditingController();
    final experience = TextEditingController(text: '0');
    final fee = TextEditingController(text: '0');
    final phone = TextEditingController();
    final email = TextEditingController();
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '17:00');
    final selectedDays = <String>{};
    final departments = await widget.db.getAllDepartments();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Doctor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: specialty,
                      decoration: const InputDecoration(labelText: 'Specialty'),
                    ),
                    departments.isEmpty
                        ? TextField(
                            controller: department,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: department.text.isEmpty
                                ? null
                                : department.text,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                            ),
                            items: departments
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d.name,
                                    child: Text(d.name ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setDialogState(
                                () => department.text = value ?? '',
                              );
                            },
                          ),
                    TextField(
                      controller: experience,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Experience',
                      ),
                    ),
                    TextField(
                      controller: fee,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fee'),
                    ),
                    TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    const Text('Working days'),
                    Wrap(
                      spacing: 8,
                      children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          .map((day) {
                            return FilterChip(
                              label: Text(day),
                              selected: selectedDays.contains(day),
                              onSelected: (selected) {
                                setDialogState(() {
                                  selected
                                      ? selectedDays.add(day)
                                      : selectedDays.remove(day);
                                });
                              },
                            );
                          })
                          .toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: start,
                            decoration: const InputDecoration(
                              labelText: 'Start',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: end,
                            decoration: const InputDecoration(labelText: 'End'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (name.text.isEmpty ||
                          specialty.text.isEmpty ||
                          department.text.isEmpty ||
                          selectedDays.isEmpty) {
                        throw StateError('Required fields missing');
                      }
                      await widget.db.insertDoctor(
                        Doctor(
                          name: name.text,
                          specialty: specialty.text,
                          department: department.text,
                          experience: int.tryParse(experience.text) ?? 0,
                          appointmentFees: double.tryParse(fee.text) ?? 0,
                          phone: phone.text,
                          email: email.text,
                          available: true,
                          availableDays: selectedDays.join(','),
                          availableStartTime: start.text,
                          availableEndTime: end.text,
                        ),
                      );
                      await widget.db.insertAuditLog(
                        who: widget.actorId,
                        action: 'ADD_DOCTOR',
                        targetUserId: null,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                    } catch (_) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to add doctor. Check required fields.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    name.dispose();
    specialty.dispose();
    department.dispose();
    experience.dispose();
    fee.dispose();
    phone.dispose();
    email.dispose();
    start.dispose();
    end.dispose();
  }
}

class _DoctorCard extends StatelessWidget {
  final DatabaseHelper db;
  final int? actorId;
  final Doctor doctor;

  const _DoctorCard({required this.db, this.actorId, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.rawQuery(
        'SELECT COUNT(*) AS count FROM appointments WHERE doctor_id = ? AND date(date) = date(?)',
        [doctor.id, _today()],
      ),
      builder: (context, snapshot) {
        final count = snapshot.data?.first['count'] as int? ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: AppAvatar(label: doctor.name?.substring(0, 1) ?? 'D'),
            title: Text(
              doctor.name ?? doctor.specialty ?? 'Doctor ${doctor.id}',
            ),
            subtitle: Text(
              '${doctor.specialty ?? ''} • ${doctor.department ?? ''} • ${doctor.status} • $count today',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                try {
                  if (value == 'edit') {
                    await _showEditDoctor(context, db, actorId, doctor);
                  } else if (value == 'toggle') {
                    await db.updateDoctor(
                      doctor.copyWith(
                        status: doctor.status == 'Active'
                            ? 'Inactive'
                            : 'Active',
                      ),
                    );
                    await db.insertAuditLog(
                      who: actorId,
                      action: 'TOGGLE_DOCTOR_STATUS',
                      targetUserId: doctor.userId,
                    );
                  } else if (value == 'schedule') {
                    await _showSchedule(context, doctor);
                  } else if (value == 'department') {
                    await _showAssignDepartment(context, db, actorId, doctor);
                  }
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Action failed.')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text('Toggle Active Status'),
                ),
                PopupMenuItem(value: 'schedule', child: Text('View Schedule')),
                PopupMenuItem(
                  value: 'department',
                  child: Text('Assign Department'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showEditDoctor(
  BuildContext context,
  DatabaseHelper db,
  int? actorId,
  Doctor doctor,
) async {
  final name = TextEditingController(text: doctor.name ?? '');
  final specialty = TextEditingController(text: doctor.specialty ?? '');
  final department = TextEditingController(text: doctor.department ?? '');
  final experience = TextEditingController(text: doctor.experience.toString());
  final fee = TextEditingController(text: doctor.appointmentFees.toString());
  final phone = TextEditingController(text: doctor.phone ?? '');
  final email = TextEditingController(text: doctor.email ?? '');
  final status = TextEditingController(text: doctor.status);
  final days = TextEditingController(text: doctor.availableDays ?? '');
  final start = TextEditingController(text: doctor.availableStartTime ?? '');
  final end = TextEditingController(text: doctor.availableEndTime ?? '');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: specialty,
              decoration: const InputDecoration(labelText: 'Specialty'),
            ),
            TextField(
              controller: department,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            TextField(
              controller: experience,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Experience'),
            ),
            TextField(
              controller: fee,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fee'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: status,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            TextField(
              controller: days,
              decoration: const InputDecoration(labelText: 'Working days'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: start,
                    decoration: const InputDecoration(labelText: 'Start'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: end,
                    decoration: const InputDecoration(labelText: 'End'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (name.text.isEmpty ||
                      specialty.text.isEmpty ||
                      department.text.isEmpty ||
                      status.text.isEmpty) {
                    throw StateError('Required fields missing');
                  }
                  await db.updateDoctor(
                    doctor.copyWith(
                      name: name.text,
                      specialty: specialty.text,
                      department: department.text,
                      experience: int.tryParse(experience.text) ?? 0,
                      appointmentFees: double.tryParse(fee.text) ?? 0,
                      phone: phone.text,
                      email: email.text,
                      status: status.text,
                      availableDays: days.text,
                      availableStartTime: start.text,
                      availableEndTime: end.text,
                    ),
                  );
                  await db.insertAuditLog(
                    who: actorId,
                    action: 'EDIT_DOCTOR',
                    targetUserId: doctor.userId,
                  );
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                } catch (_) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(content: Text('Failed to update doctor.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ),
  );
  name.dispose();
  specialty.dispose();
  department.dispose();
  experience.dispose();
  fee.dispose();
  phone.dispose();
  email.dispose();
  status.dispose();
  days.dispose();
  start.dispose();
  end.dispose();
}

Future<void> _showSchedule(BuildContext context, Doctor doctor) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('View Schedule'),
      content: Text(
        '${doctor.name ?? 'Doctor'}\nDays: ${doctor.availableDays ?? 'Not set'}\nHours: ${doctor.availableStartTime ?? '-'} to ${doctor.availableEndTime ?? '-'}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _showAssignDepartment(
  BuildContext context,
  DatabaseHelper db,
  int? actorId,
  Doctor doctor,
) async {
  final departments = await db.getAllDepartments();
  if (!context.mounted) return;
  if (departments.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Create a department first.')));
    return;
  }
  var selected = doctor.department;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Assign Department'),
        content: DropdownButton<String>(
          value: selected,
          items: departments
              .map(
                (d) =>
                    DropdownMenuItem(value: d.name, child: Text(d.name ?? '')),
              )
              .toList(),
          onChanged: (value) => setDialogState(() => selected = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await db.updateDoctor(doctor.copyWith(department: selected));
              await db.insertAuditLog(
                who: actorId,
                action: 'ASSIGN_DOCTOR_DEPARTMENT',
                targetUserId: doctor.userId,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class _DepartmentsSection extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _DepartmentsSection({required this.db, this.actorId});

  @override
  State<_DepartmentsSection> createState() => _DepartmentsSectionState();
}

class _DepartmentsSectionState extends State<_DepartmentsSection> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Departments',
            action: ElevatedButton(
              onPressed: () =>
                  _addDepartment(context, widget.db, widget.actorId),
              child: const Text('Add Department'),
            ),
          ),
          FutureBuilder<List<Department>>(
            future: widget.db.getAllDepartments(),
            builder: (context, snapshot) {
              final departments = snapshot.data ?? [];
              return Column(
                children: departments
                    .map(
                      (department) => FutureBuilder<List<Map<String, dynamic>>>(
                        future: widget.db.rawQuery(
                          'SELECT COUNT(*) AS count FROM doctors WHERE department = ?',
                          [department.name],
                        ),
                        builder: (context, snapshot) {
                          final count =
                              snapshot.data?.first['count'] as int? ?? 0;
                          final departmentStatus = department.status;
                          return ListTile(
                            title: Text(
                              department.name ?? 'Department ${department.id}',
                            ),
                            subtitle: Text(
                              '$count doctors • avg wait ${department.avgWaitMinutes.toStringAsFixed(0)} min • $departmentStatus',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _editDepartment(
                                context,
                                widget.db,
                                widget.actorId,
                                department,
                              ),
                              child: const Text('Edit'),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addDepartment(
    BuildContext context,
    DatabaseHelper db,
    int? actorId,
  ) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final doctors = await db.getAllDoctors();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        int? selectedDoctorId;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Add Department'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Head Doctor'),
                  items: doctors
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name ?? 'Doctor ${d.id}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedDoctorId = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (name.text.isEmpty) throw StateError('Name required');
                    await db.insertDepartment(
                      Department(
                        name: name.text,
                        description: description.text,
                        headDoctorId: selectedDoctorId,
                      ),
                    );
                    await db.insertAuditLog(
                      who: actorId,
                      action: 'ADD_DEPARTMENT',
                      targetUserId: null,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  } catch (_) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add department.'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    name.dispose();
    description.dispose();
  }

  Future<void> _editDepartment(
    BuildContext context,
    DatabaseHelper db,
    int? actorId,
    Department department,
  ) async {
    final description = TextEditingController(
      text: department.description ?? '',
    );
    final avgWait = TextEditingController(
      text: department.avgWaitMinutes.toString(),
    );
    final status = TextEditingController(text: department.status);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: avgWait,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Avg Wait Minutes'),
            ),
            TextField(
              controller: status,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await db.updateDepartment(
                  department.copyWith(
                    description: description.text,
                    avgWaitMinutes: double.tryParse(avgWait.text) ?? 0,
                    status: status.text,
                  ),
                );
                await db.insertAuditLog(
                  who: actorId,
                  action: 'EDIT_DEPARTMENT',
                  targetUserId: department.headDoctorId,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (_) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Failed to update department.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    description.dispose();
    avgWait.dispose();
    status.dispose();
  }
}

class _StaffSection extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _StaffSection({required this.db, this.actorId});

  @override
  State<_StaffSection> createState() => _StaffSectionState();
}

class _StaffSectionState extends State<_StaffSection> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: FutureBuilder<List<AdminStaff>>(
        future: widget.db.getAllAdminStaff(),
        builder: (context, snapshot) {
          final staff = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Staff Roster',
                action: ElevatedButton(
                  onPressed: () =>
                      _addStaff(context, widget.db, widget.actorId),
                  child: const Text('Add Staff'),
                ),
              ),
              ...staff.map(
                (member) => ListTile(
                  leading: AppAvatar(
                    label: member.name?.substring(0, 1) ?? 'S',
                  ),
                  title: Text(member.name ?? 'Staff ${member.id}'),
                  subtitle: Text(
                    '${member.role} • ${member.department ?? '-'} • ${member.shiftPattern ?? '-'} • ${member.status}',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _showShiftSchedule(context, staff),
                child: const Text('View Shift Schedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addStaff(
    BuildContext context,
    DatabaseHelper db,
    int? actorId,
  ) async {
    final name = TextEditingController();
    final role = TextEditingController(text: 'Nurse');
    final department = TextEditingController();
    final shift = TextEditingController();
    final phone = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: role,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            TextField(
              controller: department,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            TextField(
              controller: shift,
              decoration: const InputDecoration(labelText: 'Shift Pattern'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (name.text.isEmpty || role.text.isEmpty) {
                  throw StateError('Required fields missing');
                }
                await db.insertAdminStaff(
                  AdminStaff(
                    name: name.text,
                    role: role.text,
                    department: department.text,
                    shiftPattern: shift.text,
                    phone: phone.text,
                    joiningDate: _today(),
                  ),
                );
                await db.insertAuditLog(
                  who: actorId,
                  action: 'ADD_STAFF',
                  targetUserId: null,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (_) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Failed to add staff.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    role.dispose();
    department.dispose();
    shift.dispose();
    phone.dispose();
  }
}

Future<void> _showShiftSchedule(
  BuildContext context,
  List<AdminStaff> staff,
) async {
  final days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Weekly Shift Schedule'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Staff')),
              ...days.map((day) => DataColumn(label: Text(day))),
            ],
            rows: staff.map((member) {
              final shift = member.shiftPattern ?? 'Off';
              return DataRow(
                cells: [
                  DataCell(Text(member.name ?? 'Staff ${member.id}')),
                  ...days.map((_) => DataCell(Text(shift))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _LeaveApprovalSection extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _LeaveApprovalSection({required this.db, this.actorId});

  @override
  State<_LeaveApprovalSection> createState() => _LeaveApprovalSectionState();
}

class _LeaveApprovalSectionState extends State<_LeaveApprovalSection> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: FutureBuilder<List<LeaveRequest>>(
        future: widget.db
            .rawQuery('SELECT * FROM leave_requests WHERE status = ?', [
              'Pending',
            ])
            .then((rows) => rows.map(LeaveRequest.fromMap).toList()),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Leave Approval'),
              ...requests.map(
                (request) => ListTile(
                  title: Text('Staff ${request.staffId}'),
                  subtitle: Text(
                    '${request.leaveType} • ${request.startDate} to ${request.endDate} • ${request.reason}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _approve(request),
                        icon: const Icon(Icons.check),
                      ),
                      IconButton(
                        onPressed: () => _reject(request),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _approve(LeaveRequest request) async {
    await widget.db.updateLeaveRequestStatus(
      id: request.id!,
      status: 'Approved',
    );
    await widget.db.insertAuditLog(
      who: widget.actorId,
      action: 'APPROVE_LEAVE',
      targetUserId: request.staffId,
    );
  }

  Future<void> _reject(LeaveRequest request) async {
    await widget.db.updateLeaveRequestStatus(
      id: request.id!,
      status: 'Rejected',
    );
    await widget.db.insertAuditLog(
      who: widget.actorId,
      action: 'REJECT_LEAVE',
      targetUserId: request.staffId,
    );
  }
}

class _FleetTab extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _FleetTab({required this.db, this.actorId});

  @override
  State<_FleetTab> createState() => _FleetTabState();
}

class _FleetTabState extends State<_FleetTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<List<Ambulance>>(
          future: widget.db.getAllAmbulances(),
          builder: (context, snapshot) {
            final ambulances = snapshot.data ?? [];
            return Column(
              children: ambulances
                  .map(
                    (ambulance) => _AmbulanceCard(
                      db: widget.db,
                      actorId: widget.actorId,
                      ambulance: ambulance,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AmbulanceCard extends StatelessWidget {
  final DatabaseHelper db;
  final int? actorId;
  final Ambulance ambulance;

  const _AmbulanceCard({
    required this.db,
    this.actorId,
    required this.ambulance,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ambulance.vehicleNumber ?? 'Ambulance ${ambulance.id}'),
          Text('${ambulance.status} • ETA ${ambulance.eta ?? '-'}'),
          Row(
            children: [
              ElevatedButton(
                onPressed: ambulance.status == 'Available'
                    ? () => _dispatch(context)
                    : null,
                child: const Text('Dispatch'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () =>
                    db.updateAmbulance(id: ambulance.id!, status: 'Available'),
                child: const Text('Return to Base'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _dispatch(BuildContext context) async {
    final destination = TextEditingController();
    final reason = TextEditingController();
    final eta = TextEditingController(text: '12 min');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dispatch Ambulance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: destination),
            TextField(controller: reason),
            TextField(controller: eta),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await db.updateAmbulance(
                  id: ambulance.id!,
                  status: 'On call',
                  dispatchTime: DateTime.now().toIso8601String(),
                  destination: destination.text,
                  eta: eta.text,
                );
                await db.insertAuditLog(
                  who: actorId,
                  action: 'DISPATCH_AMBULANCE',
                  targetUserId: actorId,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (_) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Dispatch failed.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    destination.dispose();
    reason.dispose();
    eta.dispose();
  }
}

class _AuditTab extends StatefulWidget {
  final DatabaseHelper db;
  final int? actorId;

  const _AuditTab({required this.db, this.actorId});

  @override
  State<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<_AuditTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Users',
                action: ElevatedButton(
                  onPressed: () => _addUser(context),
                  child: const Text('Add User'),
                ),
              ),
              FutureBuilder<List<User>>(
                future: widget.db.getAllUsers(),
                builder: (context, snapshot) {
                  final users = snapshot.data ?? [];
                  return Column(
                    children: users
                        .map(
                          (user) => _UserRow(
                            db: widget.db,
                            actorId: widget.actorId,
                            user: user,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: FutureBuilder<List<AuditEntry>>(
            future: widget.db.getAllAuditLogs(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Audit Log'),
                  ...logs.map(
                    (log) => Text('${log.createdAt} • ${log.action}'),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addUser(BuildContext context) async {
    final username = TextEditingController();
    final password = TextEditingController();
    final role = TextEditingController(text: 'staff');
    final linkedEntity = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: username),
            TextField(controller: password, obscureText: true),
            TextField(
              controller: role,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            TextField(
              controller: linkedEntity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Linked Entity ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (username.text.isEmpty || password.text.isEmpty) {
                  throw StateError('Required fields missing');
                }
                final user = User(
                  username: username.text,
                  password: password.text,
                  isHospitalAdmin: role.text == 'admin',
                  isDoctor: role.text == 'doctor',
                  isStaffMember: role.text == 'staff',
                  isPatient: role.text == 'patient',
                  isLab: role.text == 'lab',
                  isPharmacy: role.text == 'pharmacy',
                  linkedEntityId: int.tryParse(linkedEntity.text),
                );
                final id = await widget.db.insertUser(user);
                await widget.db.insertAuditLog(
                  who: widget.actorId,
                  action: 'ADD_USER',
                  targetUserId: id,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (_) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Failed to add user.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    username.dispose();
    password.dispose();
    role.dispose();
    linkedEntity.dispose();
  }
}

class _UserRow extends StatelessWidget {
  final DatabaseHelper db;
  final int? actorId;
  final User user;

  const _UserRow({required this.db, this.actorId, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppAvatar(label: user.username?.substring(0, 1) ?? 'U'),
      title: Text(user.username ?? 'User ${user.id}'),
      subtitle: Text(
        '${user.role.label} • ${user.lastLogin ?? '-'} • ${user.isBlocked ? 'Blocked' : 'Active'}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          try {
            if (value == 'reset') {
              await _resetPassword(context, db, actorId, user);
            } else if (value == 'role') {
              await _changeRole(context, db, actorId, user);
            } else if (value == 'block') {
              final blocked = !user.isBlocked;
              await db.updateUser(user.copyWith(isBlocked: blocked));
              await db.insertAuditLog(
                who: actorId,
                action: blocked ? 'BLOCK_USER' : 'UNBLOCK_USER',
                targetUserId: user.id,
              );
            }
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User update failed.')),
            );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'reset', child: Text('Reset Password')),
          PopupMenuItem(value: 'role', child: Text('Change Role')),
          PopupMenuItem(value: 'block', child: Text('Block/Unblock')),
        ],
      ),
    );
  }
}

Future<void> _resetPassword(
  BuildContext context,
  DatabaseHelper db,
  int? actorId,
  User user,
) async {
  final password = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reset Password'),
      content: TextField(
        controller: password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'New password'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              if (password.text.isEmpty) throw StateError('Password required');
              await db.updateUser(user.copyWith(password: password.text));
              await db.insertAuditLog(
                who: actorId,
                action: 'RESET_PASSWORD',
                targetUserId: user.id,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            } catch (_) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Failed to reset password.')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  password.dispose();
}

Future<void> _changeRole(
  BuildContext context,
  DatabaseHelper db,
  int? actorId,
  User user,
) async {
  var selected = user.role;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Change Role'),
        content: DropdownButton<UserRole>(
          value: selected,
          items: UserRole.values
              .where((role) => role != UserRole.guest)
              .map(
                (role) =>
                    DropdownMenuItem(value: role, child: Text(role.label)),
              )
              .toList(),
          onChanged: (value) => setDialogState(() => selected = value!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await db.updateUser(
                user.copyWith(
                  isHospitalAdmin: selected == UserRole.admin,
                  isDoctor: selected == UserRole.doctor,
                  isStaffMember: selected == UserRole.staff,
                  isPatient: selected == UserRole.patient,
                  isLab: selected == UserRole.lab,
                  isPharmacy: selected == UserRole.pharmacy,
                ),
              );
              await db.insertAuditLog(
                who: actorId,
                action: 'CHANGE_USER_ROLE',
                targetUserId: user.id,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

class _MiniBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;

  const _MiniBarChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    return Row(
      children: List.generate(
        values.length,
        (index) => Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: max == 0 ? 0 : 80 * values[index] / max,
                    color: index == 0
                        ? Colors.blue
                        : index == 1
                        ? Colors.green
                        : index == 2
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ),
              Text(labels[index], style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeakHoursChart extends StatelessWidget {
  final DatabaseHelper db;

  const _PeakHoursChart({required this.db});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Peak Hours'),
        SizedBox(
          height: 120,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: db.rawQuery(
              'SELECT time, COUNT(*) AS count FROM appointments GROUP BY time',
            ),
            builder: (context, snapshot) {
              final rows = snapshot.data ?? [];
              final values = List<int>.generate(
                13,
                (index) => rows
                    .where(
                      (row) =>
                          (row['time'] as String?)?.startsWith(
                            '${8 + index}:',
                          ) ==
                          true,
                    )
                    .fold<int>(
                      0,
                      (sum, row) => sum + (row['count'] as int? ?? 0),
                    ),
              );
              return Row(
                children: List.generate(
                  values.length,
                  (index) => Expanded(
                    child: Column(
                      children: [
                        Spacer(),
                        Container(
                          height: values[index].toDouble(),
                          color: Colors.blueAccent,
                        ),
                        Text(
                          '${8 + index}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
