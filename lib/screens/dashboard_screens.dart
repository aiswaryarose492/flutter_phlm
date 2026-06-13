import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../providers/auth_provider.dart';

PreferredSizeWidget _dashboardAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Consumer<AuthProvider>(
          builder: (_, auth, _) => Center(
            child: Text(
              auth.userDisplayName,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Sign Out',
        onPressed: () async {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          await auth.logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        },
      ),
    ],
  );
}

class HospitalDashboardScreen extends StatelessWidget {
  const HospitalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleDashboard(role: _DashboardRole.hospital);
  }
}

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleDashboard(role: _DashboardRole.doctor);
  }
}

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleDashboard(role: _DashboardRole.patient);
  }
}

class LabDashboardScreen extends StatelessWidget {
  const LabDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleDashboard(role: _DashboardRole.lab);
  }
}

class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleDashboard(role: _DashboardRole.pharmacy);
  }
}

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleDashboard(role: _DashboardRole.staff);
  }
}

enum _DashboardRole { hospital, doctor, patient, lab, pharmacy, staff }

class _RoleDashboard extends StatefulWidget {
  final _DashboardRole role;

  const _RoleDashboard({required this.role});

  @override
  State<_RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends State<_RoleDashboard> {
  final _db = DatabaseHelper();
  late final Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DashboardData> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final userId = user?.id ?? 0;

    return switch (widget.role) {
      _DashboardRole.hospital => _loadHospitalData(),
      _DashboardRole.doctor => _loadDoctorData(userId),
      _DashboardRole.patient => _loadPatientData(userId),
      _DashboardRole.lab => _loadLabData(),
      _DashboardRole.pharmacy => _loadPharmacyData(),
      _DashboardRole.staff => _loadStaffData(),
    };
  }

  Future<_DashboardData> _loadHospitalData() async {
    final db = await _db.database;
    final users = await _count(db, 'users');
    final doctors = await _count(db, 'users', where: 'is_doctor = 1');
    final patients = await _count(db, 'patients');
    final appointments = await _count(db, 'appointments');
    final pendingLabs = await _count(
      db,
      'lab_orders',
      where: "status != 'Completed'",
    );
    final lowStock = await _count(
      db,
      'medicines',
      where: 'stock_qty <= reorder_level',
    );
    final departments = await db.rawQuery('''
      SELECT d.name, d.status, d.floor, d.avg_wait_minutes,
             COUNT(doc.id) AS doctor_count
      FROM departments d
      LEFT JOIN doctors doc ON doc.department = d.name
      GROUP BY d.id, d.name, d.status, d.floor, d.avg_wait_minutes
      ORDER BY d.name
    ''');
    final recentAppointments = await db.rawQuery('''
      SELECT a.id, a.date, a.time, a.status, a.symptoms,
             COALESCE(pu.first_name || ' ' || pu.last_name, 'Patient') AS patient_name,
             COALESCE(du.first_name || ' ' || du.last_name, 'Doctor') AS doctor_name
      FROM appointments a
      LEFT JOIN users pu ON a.patient_id = pu.id
      LEFT JOIN users du ON a.doctor_id = du.id
      ORDER BY a.date DESC, a.time DESC
      LIMIT 6
    ''');
    return _DashboardData(
      stats: [
        _Stat('Users', users.toString(), Icons.people, Colors.blue),
        _Stat(
          'Doctors',
          doctors.toString(),
          Icons.medical_services,
          Colors.teal,
        ),
        _Stat(
          'Patients',
          patients.toString(),
          Icons.person_outline,
          Colors.green,
        ),
        _Stat(
          'Appointments',
          appointments.toString(),
          Icons.calendar_today,
          Colors.orange,
        ),
        _Stat(
          'Pending Labs',
          pendingLabs.toString(),
          Icons.science,
          Colors.purple,
        ),
        _Stat(
          'Low Stock',
          lowStock.toString(),
          Icons.inventory_2_outlined,
          Colors.red,
        ),
      ],
      quickActions: const [
        _QuickAction('Departments', Icons.business, '/department_doctors'),
        _QuickAction('Emergency', Icons.sos, null),
        _QuickAction('Staff Tasks', Icons.task_alt, null),
      ],
      sections: [
        _Section(
          title: 'Departments',
          items: departments
              .map(
                (row) => _ListItem(
                  title: row['name']?.toString() ?? 'Department',
                  subtitle:
                      'Floor ${row['floor'] ?? 'N/A'} · ${row['doctor_count']} doctor(s)',
                  chip: row['status']?.toString() ?? 'Active',
                ),
              )
              .toList(),
        ),
        _Section(
          title: 'Recent Appointments',
          items: recentAppointments
              .map(
                (row) => _ListItem(
                  title: row['patient_name']?.toString() ?? 'Patient',
                  subtitle:
                      '${row['date']} ${row['time']} · ${row['doctor_name']}',
                  chip: row['status']?.toString() ?? 'Scheduled',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<_DashboardData> _loadDoctorData(int userId) async {
    final db = await _db.database;
    final doctorIdRows = await db.query(
      'doctors',
      columns: const ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final doctorId = doctorIdRows.isNotEmpty
        ? doctorIdRows.first['id'] as int? ?? 0
        : 0;
    final appointments = await _count(
      db,
      'appointments',
      where: 'doctor_id = ?',
      whereArgs: [doctorId],
    );
    final upcoming = await _count(
      db,
      'appointments',
      where: 'doctor_id = ? AND status != ?',
      whereArgs: [doctorId, 'Completed'],
    );
    final patients = await _countDistinct(
      db,
      'appointments',
      'patient_id',
      where: 'doctor_id = ?',
      whereArgs: [doctorId],
    );
    final pendingLabs = await _count(
      db,
      'lab_orders',
      where: 'doctor_id = ? AND status != ?',
      whereArgs: [doctorId, 'Completed'],
    );
    final recentAppointments = await db.rawQuery(
      '''
      SELECT a.id, a.date, a.time, a.status, a.symptoms,
             COALESCE(pu.first_name || ' ' || pu.last_name, 'Patient') AS patient_name
      FROM appointments a
      LEFT JOIN users pu ON a.patient_id = pu.id
      WHERE a.doctor_id = ?
      ORDER BY a.date DESC, a.time DESC
      LIMIT 6
    ''',
      [doctorId],
    );
    return _DashboardData(
      stats: [
        _Stat(
          'Appointments',
          appointments.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _Stat('Upcoming', upcoming.toString(), Icons.schedule, Colors.teal),
        _Stat('Patients', patients.toString(), Icons.people, Colors.green),
        _Stat(
          'Pending Labs',
          pendingLabs.toString(),
          Icons.science,
          Colors.purple,
        ),
      ],
      quickActions: const [
        _QuickAction('Queue', Icons.queue, null),
        _QuickAction('Prescriptions', Icons.receipt_long, null),
        _QuickAction('Availability', Icons.event_available, null),
      ],
      sections: [
        _Section(
          title: 'Recent Appointments',
          items: recentAppointments
              .map(
                (row) => _ListItem(
                  title: row['patient_name']?.toString() ?? 'Patient',
                  subtitle:
                      '${row['date']} ${row['time']} · ${row['symptoms']}',
                  chip: row['status']?.toString() ?? 'Scheduled',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<_DashboardData> _loadPatientData(int userId) async {
    final db = await _db.database;
    final patientRows = await db.query(
      'patients',
      columns: const ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final patientId = patientRows.isNotEmpty
        ? patientRows.first['id'] as int? ?? 0
        : 0;
    final appointments = await _count(
      db,
      'appointments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    final labReports = await _count(
      db,
      'lab_reports',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    final prescriptions = await _count(
      db,
      'prescriptions',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    final points = await _db.getHealthRewardPoints(patientId: patientId);
    final recentAppointments = await db.rawQuery(
      '''
      SELECT a.id, a.date, a.time, a.status, a.symptoms,
             COALESCE(du.first_name || ' ' || du.last_name, 'Doctor') AS doctor_name
      FROM appointments a
      LEFT JOIN users du ON a.doctor_id = du.id
      WHERE a.patient_id = ?
      ORDER BY a.date DESC, a.time DESC
      LIMIT 6
    ''',
      [patientId],
    );
    final labRows = await db.rawQuery(
      '''
      SELECT id,
             'Report' AS title,
             'Lab Report' AS test_type,
             CASE WHEN patient_visible = 1 THEN 'Ready' ELSE 'Pending' END AS result,
             published_at AS uploaded_at
      FROM lab_reports
      WHERE result_id IN (
        SELECT id FROM lab_results WHERE order_id IN (
          SELECT id FROM lab_orders WHERE patient_id = ?
        )
      ) OR patient_visible = 1
      ORDER BY published_at DESC
      LIMIT 5
    ''',
      [patientId],
    );
    return _DashboardData(
      stats: [
        _Stat(
          'Appointments',
          appointments.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _Stat(
          'Lab Reports',
          labReports.toString(),
          Icons.science,
          Colors.purple,
        ),
        _Stat(
          'Prescriptions',
          prescriptions.toString(),
          Icons.medication,
          Colors.teal,
        ),
        _Stat(
          'Reward Points',
          points.toString(),
          Icons.workspace_premium,
          Colors.orange,
        ),
      ],
      quickActions: const [
        _QuickAction(
          'Book Appointment',
          Icons.add_circle_outline,
          '/department_doctors',
        ),
        _QuickAction('Lab Reports', Icons.folder_shared, null),
        _QuickAction('Family', Icons.family_restroom, null),
      ],
      sections: [
        _Section(
          title: 'Upcoming & Recent Appointments',
          items: recentAppointments
              .map(
                (row) => _ListItem(
                  title: row['doctor_name']?.toString() ?? 'Doctor',
                  subtitle:
                      '${row['date']} ${row['time']} · ${row['symptoms']}',
                  chip: row['status']?.toString() ?? 'Scheduled',
                ),
              )
              .toList(),
        ),
        _Section(
          title: 'Latest Lab Reports',
          items: labRows
              .map(
                (row) => _ListItem(
                  title: row['title']?.toString() ?? 'Lab Report',
                  subtitle: '${row['test_type']} · ${row['uploaded_at']}',
                  chip: row['result']?.toString().isNotEmpty == true
                      ? 'Ready'
                      : 'Pending',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<_DashboardData> _loadLabData() async {
    final db = await _db.database;
    final pending = await _count(
      db,
      'lab_orders',
      where: "status != 'Completed'",
    );
    final completed = await _count(
      db,
      'lab_orders',
      where: "status = 'Completed'",
    );
    final urgent = await _count(
      db,
      'lab_orders',
      where: "priority = 'Urgent' AND status != 'Completed'",
    );
    final reports = await _count(db, 'lab_reports');
    final orders = await db.rawQuery('''
      SELECT lo.id, lo.priority, lo.status, lo.created_at,
             COALESCE(pu.first_name || ' ' || pu.last_name, 'Patient') AS patient_name,
             COALESCE(du.first_name || ' ' || du.last_name, 'Doctor') AS doctor_name,
             lo.tests_json
      FROM lab_orders lo
      LEFT JOIN users pu ON lo.patient_id = pu.id
      LEFT JOIN users du ON lo.doctor_id = du.id
      ORDER BY CASE lo.priority WHEN 'Urgent' THEN 0 ELSE 1 END, lo.created_at DESC
      LIMIT 8
    ''');
    return _DashboardData(
      stats: [
        _Stat(
          'Pending Orders',
          pending.toString(),
          Icons.pending_actions,
          Colors.orange,
        ),
        _Stat(
          'Completed',
          completed.toString(),
          Icons.check_circle_outline,
          Colors.green,
        ),
        _Stat('Urgent', urgent.toString(), Icons.priority_high, Colors.red),
        _Stat('Reports', reports.toString(), Icons.article, Colors.purple),
      ],
      quickActions: const [
        _QuickAction('Add Order', Icons.add_circle_outline, null),
        _QuickAction('Upload Report', Icons.upload_file, null),
        _QuickAction('Notifications', Icons.notifications_active, null),
      ],
      sections: [
        _Section(
          title: 'Lab Orders',
          items: orders
              .map(
                (row) => _ListItem(
                  title: row['patient_name']?.toString() ?? 'Patient',
                  subtitle: '${row['doctor_name']} · ${row['created_at']}',
                  chip: '${row['priority']} · ${row['status']}',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<_DashboardData> _loadPharmacyData() async {
    final db = await _db.database;
    final pendingRx = await _count(
      db,
      'prescriptions',
      where: 'is_dispensed = 0',
    );
    final lowStock = await _count(
      db,
      'medicines',
      where: 'stock_qty <= reorder_level',
    );
    final refills = await _count(
      db,
      'refill_requests',
      where: "status != 'Completed'",
    );
    final dispensed = await _count(db, 'dispensing_log');
    final medicines = await db.rawQuery('''
      SELECT id, name, stock_qty, reorder_level, unit, expiry_date
      FROM medicines
      WHERE stock_qty <= reorder_level
      ORDER BY stock_qty ASC
      LIMIT 8
    ''');
    final prescriptions = await db.rawQuery('''
      SELECT p.id, p.created_at, p.notes,
             COALESCE(pu.first_name || ' ' || pu.last_name, 'Patient') AS patient_name
      FROM prescriptions p
      LEFT JOIN users pu ON p.patient_id = pu.id
      WHERE p.is_dispensed = 0
      ORDER BY p.created_at DESC
      LIMIT 6
    ''');
    return _DashboardData(
      stats: [
        _Stat(
          'Pending Rx',
          pendingRx.toString(),
          Icons.receipt_long,
          Colors.teal,
        ),
        _Stat(
          'Low Stock',
          lowStock.toString(),
          Icons.inventory_2_outlined,
          Colors.red,
        ),
        _Stat('Refills', refills.toString(), Icons.refresh, Colors.orange),
        _Stat(
          'Dispensed',
          dispensed.toString(),
          Icons.local_pharmacy,
          Colors.green,
        ),
      ],
      quickActions: const [
        _QuickAction('Dispense', Icons.medication, null),
        _QuickAction('Stock Update', Icons.inventory, null),
        _QuickAction('Refills', Icons.sync_alt, null),
      ],
      sections: [
        _Section(
          title: 'Low Stock Medicines',
          items: medicines
              .map(
                (row) => _ListItem(
                  title: row['name']?.toString() ?? 'Medicine',
                  subtitle:
                      'Stock ${row['stock_qty']} ${row['unit'] ?? ''} · Reorder ${row['reorder_level']}',
                  chip: 'Expiry ${row['expiry_date'] ?? 'N/A'}',
                ),
              )
              .toList(),
        ),
        _Section(
          title: 'Pending Prescriptions',
          items: prescriptions
              .map(
                (row) => _ListItem(
                  title: row['patient_name']?.toString() ?? 'Patient',
                  subtitle: row['notes']?.toString() ?? 'Prescription pending',
                  chip: row['created_at']?.toString() ?? 'Pending',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<_DashboardData> _loadStaffData() async {
    final db = await _db.database;
    final openTasks = await _count(
      db,
      'staff_tasks',
      where: "status != 'Completed'",
    );
    final admissions = await _count(
      db,
      'patient_admissions',
      where: "status = 'Admitted'",
    );
    final availableBeds = await _count(
      db,
      'beds',
      where: "status = 'Available'",
    );
    final emergencies = await _count(
      db,
      'emergency_cases',
      where: "status != 'Closed'",
    );
    final tasks = await db.rawQuery('''
      SELECT id, title, description, status, priority, due_date
      FROM staff_tasks
      WHERE status != 'Completed'
      ORDER BY CASE priority WHEN 'High' THEN 0 WHEN 'Medium' THEN 1 ELSE 2 END, due_date
      LIMIT 8
    ''');
    final admissionsRows = await db.rawQuery('''
      SELECT pa.id, pa.bed_number, pa.admission_reason, pa.status,
             COALESCE(pu.first_name || ' ' || pu.last_name, 'Patient') AS patient_name
      FROM patient_admissions pa
      LEFT JOIN users pu ON pa.patient_id = pu.id
      WHERE pa.status = 'Admitted'
      ORDER BY pa.admission_date DESC
      LIMIT 6
    ''');
    return _DashboardData(
      stats: [
        _Stat(
          'Open Tasks',
          openTasks.toString(),
          Icons.task_alt,
          Colors.orange,
        ),
        _Stat('Admitted', admissions.toString(), Icons.hotel, Colors.blue),
        _Stat('Beds Free', availableBeds.toString(), Icons.bed, Colors.green),
        _Stat('Emergencies', emergencies.toString(), Icons.sos, Colors.red),
      ],
      quickActions: const [
        _QuickAction('Assign Task', Icons.assignment_add, null),
        _QuickAction('Bed Status', Icons.bed, null),
        _QuickAction('Emergency', Icons.local_hospital, null),
      ],
      sections: [
        _Section(
          title: 'Staff Tasks',
          items: tasks
              .map(
                (row) => _ListItem(
                  title: row['title']?.toString() ?? 'Task',
                  subtitle: row['description']?.toString() ?? 'No description',
                  chip: '${row['priority']} · ${row['status']}',
                ),
              )
              .toList(),
        ),
        _Section(
          title: 'Admitted Patients',
          items: admissionsRows
              .map(
                (row) => _ListItem(
                  title: row['patient_name']?.toString() ?? 'Patient',
                  subtitle:
                      'Bed ${row['bed_number']} · ${row['admission_reason']}',
                  chip: row['status']?.toString() ?? 'Admitted',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<int> _count(
    Database db,
    String table, {
    String? where,
    List<Object?> whereArgs = const [],
  }) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return _toInt(rows.first['count']);
  }

  Future<int> _countDistinct(
    Database db,
    String table,
    String column, {
    String? where,
    List<Object?> whereArgs = const [],
  }) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT $column) AS count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return _toInt(rows.first['count']);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final title = switch (widget.role) {
      _DashboardRole.hospital => 'Hospital Dashboard',
      _DashboardRole.doctor => 'Doctor Dashboard',
      _DashboardRole.patient => 'Patient Dashboard',
      _DashboardRole.lab => 'Lab Dashboard',
      _DashboardRole.pharmacy => 'Pharmacy Dashboard',
      _DashboardRole.staff => 'Staff Dashboard',
    };

    return Scaffold(
      appBar: _dashboardAppBar(context, title),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = _loadData());
          await _future;
        },
        child: FutureBuilder<_DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }
            final data = snapshot.data ?? _DashboardData.empty();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(auth: auth, role: widget.role),
                  const SizedBox(height: 16),
                  _StatsGrid(stats: data.stats),
                  const SizedBox(height: 16),
                  _QuickActions(actions: data.quickActions),
                  const SizedBox(height: 16),
                  ...data.sections.map(
                    (section) => _DashboardSection(section: section),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final AuthProvider auth;
  final _DashboardRole role;

  const _HeroCard({required this.auth, required this.role});

  @override
  Widget build(BuildContext context) {
    final icon = switch (role) {
      _DashboardRole.hospital => Icons.business,
      _DashboardRole.doctor => Icons.medical_services,
      _DashboardRole.patient => Icons.person_outline,
      _DashboardRole.lab => Icons.science,
      _DashboardRole.pharmacy => Icons.local_pharmacy,
      _DashboardRole.staff => Icons.badge,
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3C5E), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.userDisplayName.isEmpty
                      ? 'Welcome'
                      : auth.userDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PHLMS Medical Center · ${_roleLabel(role)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _roleLabel(_DashboardRole role) {
    return switch (role) {
      _DashboardRole.hospital => 'Hospital Admin',
      _DashboardRole.doctor => 'Doctor',
      _DashboardRole.patient => 'Patient',
      _DashboardRole.lab => 'Laboratory',
      _DashboardRole.pharmacy => 'Pharmacy',
      _DashboardRole.staff => 'Staff',
    };
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_Stat> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: stats.isEmpty ? 1 : stats.length,
      itemBuilder: (_, index) {
        if (stats.isEmpty) {
          return const _EmptyCard(message: 'No statistics available');
        }
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: stat.color.withValues(alpha: 0.12),
                      child: Icon(stat.icon, color: stat.color),
                    ),
                    const Spacer(),
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: stat.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(stat.label),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  final List<_QuickAction> actions;

  const _QuickActions({required this.actions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.isEmpty ? 1 : actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          if (actions.isEmpty) {
            return const _EmptyCard(message: 'No quick actions');
          }
          final action = actions[index];
          return SizedBox(
            width: 150,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (action.route != null) {
                    Navigator.pushNamed(context, action.route!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action.title} coming soon')),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final _Section section;

  const _DashboardSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${section.items.length} item(s)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (section.items.isEmpty)
                const _EmptyCard(message: 'No records found')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: section.items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final item = section.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.medical_services,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                      trailing: _Chip(text: item.chip),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final normalized = text.toLowerCase();
    final color =
        normalized.contains('completed') ||
            normalized.contains('available') ||
            normalized.contains('active') ||
            normalized.contains('ready')
        ? Colors.green
        : normalized.contains('pending') ||
              normalized.contains('urgent') ||
              normalized.contains('high') ||
              normalized.contains('low')
        ? Colors.orange
        : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Dashboard failed to load: $message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class _DashboardData {
  final List<_Stat> stats;
  final List<_QuickAction> quickActions;
  final List<_Section> sections;

  const _DashboardData({
    required this.stats,
    required this.quickActions,
    required this.sections,
  });

  factory _DashboardData.empty() =>
      const _DashboardData(stats: [], quickActions: [], sections: []);
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat(this.label, this.value, this.icon, this.color);
}

class _QuickAction {
  final String title;
  final IconData icon;
  final String? route;

  const _QuickAction(this.title, this.icon, this.route);
}

class _Section {
  final String title;
  final List<_ListItem> items;

  const _Section({required this.title, required this.items});
}

class _ListItem {
  final String title;
  final String subtitle;
  final String chip;

  const _ListItem({
    required this.title,
    required this.subtitle,
    required this.chip,
  });
}
