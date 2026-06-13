import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/drug_interactions.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/hospital_api.dart';
import '../shared/widgets.dart';

enum _PatientTab { home, appointments, records, bills, more, consult }

class PatientShell extends StatefulWidget {
  final Widget? child;

  const PatientShell({super.key, this.child});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  final _db = DatabaseHelper();
  final _api = HospitalApi();
  int _index = 0;
  int? _activePatientId;
  Hospital? _hospital;
  List<FamilyMember> _familyMembers = const [];
  List<HealthReward> _healthRewards = const [];
  List<String> _pharmacyCart = const [];
  int _rewardPoints = 0;

  int? get activePatientId => _activePatientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialProfile());
  }

  Future<void> _loadInitialProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    Patient? patient;
    if (user?.id != null) {
      patient = await _db.getPatientByUserId(user!.id!);
    }

    final hospitals = await _api.getHospitals();
    final activePatientId = patient?.id ?? user?.id;
    final members = activePatientId == null
        ? <FamilyMember>[]
        : await _db.getFamilyMembers(patientId: activePatientId);
    await _awardRewardsForActivePatient(activePatientId);
    _loadPharmacyCart();
    if (!mounted) return;

    setState(() {
      _activePatientId = activePatientId;
      _hospital = hospitals.firstOrNull;
      _familyMembers = members;
      _loadRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = _PatientTab.values[_index];
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
          Expanded(child: widget.child ?? _bodyFor(tab)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Records'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            label: 'Consult',
          ),
        ],
      ),
      floatingActionButton: tab == _PatientTab.home
          ? FloatingActionButton.extended(
              onPressed: _launchEmergency,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.sos),
              label: const Text('SOS'),
            )
          : null,
    );
  }

  String _titleFor(_PatientTab tab) {
    switch (tab) {
      case _PatientTab.home:
        return 'Patient Dashboard';
      case _PatientTab.appointments:
        return 'Appointments';
      case _PatientTab.records:
        return 'Health Records';
      case _PatientTab.bills:
        return 'Bills';
      case _PatientTab.more:
        return 'More';
      case _PatientTab.consult:
        return 'Telemedicine';
    }
  }

  Widget _bodyFor(_PatientTab tab) {
    switch (tab) {
      case _PatientTab.home:
        return _buildHome();
      case _PatientTab.appointments:
        return _buildAppointments();
      case _PatientTab.records:
        return _buildRecords();
      case _PatientTab.bills:
        return _buildBills();
      case _PatientTab.more:
        return _buildMore();
      case _PatientTab.consult:
        return _buildConsult();
    }
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _activeProfileCard(),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Care Actions',
                subtitle:
                    'Book care, check symptoms and manage family profiles',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/patient/book'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Book Appointment'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openSymptomChecker(),
                    icon: const Icon(Icons.psychology_alt),
                    label: const Text('Check Symptoms'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/patient/book?online=true'),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Schedule Telemedicine'),
                  ),
                ],
              ),
            ],
          ),
        ),
        _futureCard<Appointment>(
          title: 'Upcoming Appointments',
          future: () => _api.getAppointments(),
          builder: (appointments) => _filteredItems(
            appointments,
            (item) => item.patientId == _activePatientId,
          ),
          empty: 'No appointments yet.',
          tile: _appointmentTile,
        ),
        _futureCard<Bill>(
          title: 'Recent Bills',
          future: () => _api.getBills(),
          builder: (bills) => _filteredItems(
            bills,
            (item) => item.patientId == _activePatientId,
          ),
          empty: 'No bills available.',
          tile: (bill) => ListTile(
            leading: const AppAvatar(label: '₹', icon: Icons.receipt_long),
            title: Text(bill.billNumber ?? 'Bill ${bill.id}'),
            subtitle: Text(
              '${bill.status} • ${bill.amount.toStringAsFixed(2)}',
            ),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Emergency'),
              Text(
                'Hospital emergency number: ${_hospital?.emergencyNumber ?? '108'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap SOS to call emergency services immediately.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activeProfileCard() {
    final member = _familyMembers
        .where((item) => item.id == _activePatientId)
        .firstOrNull;
    return AppCard(
      child: Row(
        children: [
          AppAvatar(label: member?.name ?? 'Patient'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member?.name ?? 'Patient Profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  member == null
                      ? 'Loading active profile'
                      : '${member.relation} • ${member.age} years',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointments() {
    return _futureCard<Appointment>(
      title: 'My Appointments',
      future: () => _api.getAppointments(),
      builder: (items) =>
          _filteredItems(items, (item) => item.patientId == _activePatientId),
      empty: 'No appointments found.',
      tile: _appointmentTile,
    );
  }

  Widget _buildRecords() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _api.getAppointments(),
        _api.getLabReports(),
        _api.getPrescriptions(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load health records.'));
        }

        final data = snapshot.data!;
        final appointments = (data[0] as List<Appointment>)
            .where((item) => item.patientId == _activePatientId)
            .toList();
        final appointmentIds = appointments.map((a) => a.id).toSet();

        final reports = (data[1] as List<LabReport>)
            .where((item) => item.patientId == _activePatientId)
            .toList();

        final prescriptions = (data[2] as List<Prescription>)
            .where((item) => appointmentIds.contains(item.appointmentId))
            .toList();

        final events = <_TimelineEvent>[];
        for (final appointment in appointments) {
          events.add(
            _TimelineEvent(
              icon: Icons.calendar_today,
              title: 'Appointment ${appointment.id}',
              date: appointment.date,
              status: appointment.status ?? 'Booked',
              color: Colors.blue,
            ),
          );
        }
        for (final report in reports) {
          events.add(
            _TimelineEvent(
              icon: Icons.science,
              title: report.title ?? 'Lab Report ${report.id}',
              date: report.uploadedAt,
              status: report.result ?? 'Reported',
              color: Colors.purple,
            ),
          );
        }
        for (final prescription in prescriptions) {
          events.add(
            _TimelineEvent(
              icon: Icons.medication,
              title:
                  prescription.medicines ?? 'Prescription ${prescription.id}',
              date: prescription.createdAt,
              status: prescription.isDispensed ? 'Dispensed' : 'Active',
              color: Colors.green,
            ),
          );
        }
        events.sort((a, b) => _dateFor(b.date).compareTo(_dateFor(a.date)));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Prescriptions'),
                  if (prescriptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('No prescriptions available.'),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: prescriptions.length,
                      separatorBuilder: (_, previous) =>
                          const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final rx = prescriptions[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const AppAvatar(
                            label: 'Rx',
                            icon: Icons.medication,
                          ),
                          title: Text(rx.medicines ?? 'Prescription ${rx.id}'),
                          subtitle: Text(rx.notes ?? rx.createdAt ?? ''),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Timeline',
                    subtitle: 'Appointments, lab reports and prescriptions',
                  ),
                  const SizedBox(height: 8),
                  _Timeline(events: events),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBills() {
    return _futureCard<Bill>(
      title: 'Bills',
      future: () => _api.getBills(),
      builder: (items) =>
          _filteredItems(items, (item) => item.patientId == _activePatientId),
      empty: 'No bills available.',
      tile: (bill) => ListTile(
        leading: const AppAvatar(label: '₹', icon: Icons.receipt_long),
        title: Text(bill.billNumber ?? 'Bill ${bill.id}'),
        subtitle: Text(
          '${bill.status} • Paid ${bill.paidAmount.toStringAsFixed(2)}',
        ),
        trailing: Text(bill.amount.toStringAsFixed(2)),
      ),
    );
  }

  Future<void> _loadPharmacyCart() async {
    final prescriptions = await _db.getAllPrescriptions();
    final cart = <String>{};
    for (final prescription in prescriptions) {
      final rows = _decodeMedicineRows(prescription.medicines);
      for (final row in rows) {
        final name = row['name'] as String?;
        if (name != null) cart.add(name);
      }
    }
    if (!mounted) return;
    setState(() => _pharmacyCart = cart.toList());
  }

  List<Map<String, dynamic>> _decodeMedicineRows(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final value = jsonDecode(encoded);
      if (value is List) return value.cast<Map<String, dynamic>>();
    } catch (_) {}
    return const [];
  }

  Future<void> _loadRewards() async {
    final patientId = _activePatientId;
    if (patientId == null) return;
    final rewards = await _db.getHealthRewards(patientId: patientId);
    final points = await _db.getHealthRewardPoints(patientId: patientId);
    if (!mounted) return;
    setState(() {
      _healthRewards = rewards;
      _rewardPoints = points;
    });
  }

  Future<void> _awardRewardsForActivePatient(int? patientId) async {
    if (patientId == null) return;
    final appointments = await _db.getAllAppointments();
    for (final appointment in appointments) {
      if (appointment.patientId == patientId &&
          appointment.status == 'Completed' &&
          !await _hasReward(patientId, 'Completed appointment')) {
        await _db.insertHealthReward(
          HealthReward(
            patientId: patientId,
            points: 10,
            reason: 'Completed appointment',
            earnedAt: DateTime.now().toIso8601String(),
          ),
        );
      }
    }
    final rows = await _db.rawQuery(
      '''
      SELECT lr.*, lo.patient_id AS linked_patient_id
      FROM lab_reports lr
      JOIN lab_results r ON r.id = lr.result_id
      JOIN lab_orders lo ON lo.id = r.order_id
      WHERE lr.patient_visible = 1 AND lo.patient_id = ?
      ''',
      [patientId],
    );
    for (final _ in rows) {
      if (!await _hasReward(patientId, 'Lab test completed')) {
        await _db.insertHealthReward(
          HealthReward(
            patientId: patientId,
            points: 5,
            reason: 'Lab test completed',
            earnedAt: DateTime.now().toIso8601String(),
          ),
        );
      }
    }
    if (!await _hasReward(patientId, 'Annual checkup')) {
      await _db.insertHealthReward(
        HealthReward(
          patientId: patientId,
          points: 20,
          reason: 'Annual checkup',
          earnedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  Future<bool> _hasReward(int patientId, String reason) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM health_rewards WHERE patient_id = ? AND reason = ?',
      [patientId, reason],
    );
    final value = rows.first['count'];
    final count = value is int ? value : (value as num?)?.toInt() ?? 0;
    return count > 0;
  }

  Widget _buildMore() {
    final interactions = DrugInteractionChecker.findInteractions(_pharmacyCart);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: SectionHeader(
            title: 'AI Symptom Checker',
            subtitle:
                'Enter symptoms one by one to get local department suggestions',
            action: ElevatedButton(
              onPressed: _openSymptomChecker,
              child: const Text('Check Symptoms'),
            ),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Health Rewards',
                subtitle:
                    '$_rewardPoints points • ${_milestoneTitle(_rewardPoints)}',
              ),
              Icon(
                _milestoneIcon(_rewardPoints),
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              ..._healthRewards
                  .take(5)
                  .map(
                    (reward) => ListTile(
                      leading: const Icon(Icons.workspace_premium),
                      title: Text('${reward.points} pts'),
                      subtitle: Text('${reward.reason} • ${reward.earnedAt}'),
                    ),
                  ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Pharmacy Cart',
                subtitle: 'Medicines from your prescriptions',
              ),
              if (_pharmacyCart.isEmpty)
                const Text('No medicines in pharmacy cart.')
              else
                ..._pharmacyCart.map(
                  (medicine) => ListTile(
                    leading: const Icon(Icons.medication),
                    title: Text(medicine),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          setState(() => _pharmacyCart.remove(medicine)),
                    ),
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
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Family Members',
                subtitle:
                    'Switch active profile to view appointments and records',
                action: TextButton(
                  onPressed: _showFamilyDialog,
                  child: const Text('Add'),
                ),
              ),
              if (_familyMembers.isEmpty)
                const Text('No family members added yet.')
              else
                ..._familyMembers.map(
                  (member) => ListTile(
                    leading: AppAvatar(label: member.name),
                    title: Text(member.name),
                    subtitle: Text('${member.relation} • ${member.age} years'),
                    trailing: member.id == _activePatientId
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() => _activePatientId = member.id);
                      _loadRewards();
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _milestoneIcon(int points) {
    if (points >= 200) return Icons.auto_awesome;
    if (points >= 100) return Icons.workspace_premium;
    if (points >= 50) return Icons.star;
    return Icons.spa;
  }

  String _milestoneTitle(int points) {
    if (points >= 200) return 'Platinum';
    if (points >= 100) return 'Gold';
    if (points >= 50) return 'Silver';
    return 'Bronze';
  }

  Widget _buildConsult() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Telemedicine',
                subtitle: 'Connect with available doctors',
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/patient/book?online=true'),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Schedule Telemedicine'),
              ),
            ],
          ),
        ),
        _futureCard<Doctor>(
          title: 'Available Doctors',
          future: () => _api.getDoctors(),
          builder: (items) => items.where((item) => item.available).toList(),
          empty: 'No doctors are available right now.',
          tile: (doctor) => _consultDoctorTile(doctor),
        ),
      ],
    );
  }

  Widget _consultDoctorTile(Doctor doctor) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(label: doctor.specialty ?? 'Dr'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.specialty ?? 'Doctor ${doctor.id}'),
                    Text(
                      '${doctor.department ?? ''} • ${doctor.available ? 'Available' : 'Unavailable'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openConsulting(doctor),
                icon: const Icon(Icons.videocam),
                label: const Text('Video'),
              ),
              ElevatedButton.icon(
                onPressed: () => _openConsulting(doctor),
                icon: const Icon(Icons.call),
                label: const Text('Audio'),
              ),
              ElevatedButton.icon(
                onPressed: () => _openConsulting(doctor),
                icon: const Icon(Icons.chat),
                label: const Text('Chat'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appointmentTile(Appointment appointment) {
    return ListTile(
      leading: AppAvatar(
        label: appointment.isOnline ? 'VC' : 'AP',
        icon: appointment.isOnline ? Icons.videocam : Icons.calendar_today,
      ),
      title: Text('Appointment ${appointment.id}'),
      subtitle: Text(
        '${appointment.date ?? ''} ${appointment.time ?? ''} • ${appointment.symptoms ?? ''}',
      ),
      trailing: appointment.isOnline ? const Icon(Icons.videocam) : null,
    );
  }

  Widget _futureCard<T>({
    required String title,
    String? subtitle,
    required Future<List<T>> Function() future,
    required List<T> Function(List<T> items) builder,
    required String empty,
    required Widget Function(T item) tile,
  }) {
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
          final items = builder(snapshot.data as List<T>);
          if (items.isEmpty) {
            return Text(empty);
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, previous) => const Divider(height: 1),
            itemBuilder: (_, index) => tile(items[index]),
          );
        },
      ),
    );
  }

  List<T> _filteredItems<T>(List<T> items, bool Function(T item) filter) {
    if (_activePatientId == null) return items;
    return items.where(filter).toList();
  }

  Future<void> _openSymptomChecker() {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
    );
  }

  Future<void> _openConsulting(Doctor doctor) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TelemedicineConnectingScreen(doctor: doctor),
      ),
    );
  }

  Future<void> _showFamilyDialog() async {
    final navigator = Navigator.of(context);
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final ageController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Family Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(labelText: 'Relation'),
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
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
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final user = auth.currentUser;
                Patient? patient;
                if (user?.id != null) {
                  patient = await _db.getPatientByUserId(user!.id!);
                }
                final loggedInPatientId = patient?.id ?? user?.id;
                if (loggedInPatientId == null) return;

                await _db.insertFamilyMember(
                  FamilyMember(
                    patientId: loggedInPatientId,
                    name: nameController.text.trim(),
                    relation: relationController.text.trim(),
                    age: int.tryParse(ageController.text.trim()) ?? 0,
                  ),
                );
                if (!mounted) return;
                navigator.pop();
                final members = await _db.getFamilyMembers(
                  patientId: loggedInPatientId,
                );
                setState(() => _familyMembers = members);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    relationController.dispose();
    ageController.dispose();
  }

  Future<void> _launchEmergency() async {
    final number = _hospital?.emergencyNumber ?? '108';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Call Emergency'),
          content: Text('Call Emergency: $number?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Call'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final uri = Uri.parse('tel:$number');
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer.')),
      );
    }
  }
}

class PatientBookingScreen extends StatefulWidget {
  final bool initialOnline;

  const PatientBookingScreen({super.key, this.initialOnline = false});

  @override
  State<PatientBookingScreen> createState() => _PatientBookingScreenState();
}

class _PatientBookingScreenState extends State<PatientBookingScreen> {
  final _api = HospitalApi();
  final _db = DatabaseHelper();
  final _symptomsController = TextEditingController();
  int _step = 0;
  List<Department> _departments = const [];
  List<Doctor> _doctors = const [];
  Department? _department;
  Doctor? _doctor;
  DateTime? _date;
  String? _time;
  final _slots = const [
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

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadDoctors();
  }

  Future<void> _loadDepartments() async {
    final departments = await _api.getDepartments();
    if (!mounted) return;
    setState(() => _departments = departments);
  }

  Future<void> _loadDoctors() async {
    final doctors = await _api.getDoctors();
    if (!mounted) return;
    setState(() => _doctors = doctors);
  }

  List<Doctor> get _filteredDoctors {
    if (_department == null) return _doctors;
    return _doctors
        .where(
          (doctor) =>
              doctor.department == _department!.name ||
              doctor.specialty == _department!.name,
        )
        .toList();
  }

  bool _isNextEnabled() {
    switch (_step) {
      case 0:
        return _department != null;
      case 1:
        return _doctor != null;
      case 2:
        return _date != null;
      case 3:
        return _time != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialOnline ? 'Schedule Telemedicine' : 'Book Appointment',
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 5),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _departmentStep(),
                _doctorStep(),
                _dateStep(),
                _timeStep(),
                _confirmStep(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                )
              else
                const SizedBox.shrink(),
              if (_step < 4)
                ElevatedButton(
                  onPressed: _isNextEnabled()
                      ? () => setState(() => _step++)
                      : null,
                  child: const Text('Next'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _departmentStep() {
    return _BookingStep(
      title: 'Select Department',
      child: _departments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _departments.length,
              itemBuilder: (_, index) {
                final department = _departments[index];
                final selected = department.id == _department?.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    selected: selected,
                    leading: const AppAvatar(label: 'D'),
                    title: Text(
                      department.name ?? 'Department ${department.id}',
                    ),
                    subtitle: Text(department.description ?? ''),
                    onTap: () => setState(() {
                      _department = department;
                      _doctor = null;
                    }),
                  ),
                );
              },
            ),
    );
  }

  Widget _doctorStep() {
    final doctors = _filteredDoctors;
    return _BookingStep(
      title: 'Select Doctor',
      child: doctors.isEmpty
          ? const Center(
              child: Text('No doctors available for this department.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: doctors.length,
              itemBuilder: (_, index) {
                final doctor = doctors[index];
                final selected = doctor.id == _doctor?.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    selected: selected,
                    leading: AppAvatar(label: doctor.specialty ?? 'Dr'),
                    title: Text(doctor.specialty ?? 'Doctor ${doctor.id}'),
                    subtitle: Text(
                      '${doctor.department ?? ''} • ${doctor.available ? 'Available' : 'Unavailable'}',
                    ),
                    onTap: () => setState(() => _doctor = doctor),
                  ),
                );
              },
            ),
    );
  }

  Widget _dateStep() {
    return _BookingStep(
      title: 'Choose Date',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppCard(
              child: Text(
                _date == null ? 'No date selected' : _formatDate(_date!),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Pick Future Date'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeStep() {
    return _BookingStep(
      title: 'Choose Time Slot',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: _slots.length,
          itemBuilder: (_, index) {
            final slot = _slots[index];
            final selected = slot == _time;
            return ElevatedButton(
              onPressed: () => setState(() => _time = slot),
              style: ElevatedButton.styleFrom(
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
                foregroundColor: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
              child: Text(slot),
            );
          },
        ),
      ),
    );
  }

  Widget _confirmStep() {
    return _BookingStep(
      title: 'Confirm Booking',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Summary'),
                _SummaryRow(
                  label: 'Department',
                  value: _department?.name ?? '-',
                ),
                _SummaryRow(label: 'Doctor', value: _doctor?.specialty ?? '-'),
                _SummaryRow(
                  label: 'Date',
                  value: _date == null ? '-' : _formatDate(_date!),
                ),
                _SummaryRow(label: 'Time', value: _time ?? '-'),
                _SummaryRow(
                  label: 'Mode',
                  value: widget.initialOnline ? 'Telemedicine' : 'In-person',
                ),
              ],
            ),
          ),
          TextField(
            controller: _symptomsController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Symptoms / Notes'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                _department == null ||
                    _doctor == null ||
                    _date == null ||
                    _time == null
                ? null
                : _saveAppointment,
            child: Text(
              widget.initialOnline
                  ? 'Schedule Telemedicine'
                  : 'Confirm Appointment',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _saveAppointment() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    Patient? patient;
    if (user?.id != null) {
      patient = await _db.getPatientByUserId(user!.id!);
    }
    final patientId = patient?.id ?? user?.id;
    if (patientId == null) return;

    final appointmentId = await _db.insertAppointment(
      Appointment(
        doctorId: _doctor!.id,
        patientId: patientId,
        date: _formatDate(_date!),
        time: _time,
        symptoms: _symptomsController.text.trim(),
        isOnline: widget.initialOnline,
        meetLink: widget.initialOnline ? 'telemedicine://appointment' : null,
        status: widget.initialOnline ? 'Telemedicine Scheduled' : 'Booked',
      ),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(appointmentId: appointmentId),
      ),
    );
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }
}

class _BookingStep extends StatelessWidget {
  final String title;
  final Widget child;

  const _BookingStep({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title: title),
        child,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class BookingSuccessScreen extends StatelessWidget {
  final int appointmentId;

  const BookingSuccessScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmed')),
      body: Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'Appointment ID: $appointmentId',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Your appointment has been saved.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/patient'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TelemedicineConnectingScreen extends StatefulWidget {
  final Doctor doctor;

  const TelemedicineConnectingScreen({super.key, required this.doctor});

  @override
  State<TelemedicineConnectingScreen> createState() =>
      _TelemedicineConnectingScreenState();
}

class _TelemedicineConnectingScreenState
    extends State<TelemedicineConnectingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telemedicine')),
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (_, child) {
            return Transform.scale(scale: _animation.value, child: child);
          },
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(label: widget.doctor.specialty ?? 'Dr'),
                const SizedBox(height: 16),
                Text(
                  'Connecting to ${widget.doctor.specialty ?? 'Doctor'}...',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _controller = TextEditingController();
  final _symptoms = <String>[];

  List<_SuggestedDepartment> get _suggestions {
    final text = _symptoms.join(' ').toLowerCase();
    final suggestions = <_SuggestedDepartment>[];
    if (text.contains('chest pain')) {
      suggestions.add(
        const _SuggestedDepartment(
          'Cardiology',
          'Chest pain can be related to heart conditions.',
        ),
      );
    }
    if (text.contains('fever') && text.contains('child')) {
      suggestions.add(
        const _SuggestedDepartment(
          'Pediatrics',
          'Fever in children should be reviewed by a pediatrician.',
        ),
      );
    }
    if (text.contains('skin rash') || text.contains('rash')) {
      suggestions.add(
        const _SuggestedDepartment(
          'Dermatology',
          'Skin rashes are usually handled by dermatology.',
        ),
      );
    }
    if (text.contains('headache')) {
      suggestions.add(
        const _SuggestedDepartment(
          'Neurology',
          'Recurring headaches may need neurological review.',
        ),
      );
    }
    if (text.contains('joint pain')) {
      suggestions.add(
        const _SuggestedDepartment(
          'Orthopedics',
          'Joint pain is commonly evaluated by orthopedics.',
        ),
      );
    }
    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Symptom Checker')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._symptoms.map(
                  (symptom) => Align(
                    alignment: Alignment.centerRight,
                    child: Chip(
                      label: Text(symptom),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                  ),
                ),
                if (_symptoms.length >= 3) ...[
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'Suggested Departments'),
                  ..._suggestions.map(_suggestionCard),
                  if (_suggestions.isEmpty)
                    const Text(
                      'No strong department match yet. Add more symptoms.',
                    ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Add a symptom',
                    ),
                    onSubmitted: _addSymptom,
                  ),
                ),
                IconButton(
                  onPressed: () => _addSymptom(_controller.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionCard(_SuggestedDepartment suggestion) {
    return AppCard(
      child: Row(
        children: [
          AppAvatar(label: suggestion.name.substring(0, 1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(suggestion.reason),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addSymptom(String value) {
    final symptom = value.trim();
    if (symptom.isEmpty) return;
    setState(() {
      _symptoms.add(symptom);
      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Timeline extends StatelessWidget {
  final List<_TimelineEvent> events;

  const _Timeline({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const Text('No timeline events.');
    return Column(
      children: events.asMap().entries.map((entry) {
        final isLast = entry.key == events.length - 1;
        final event = entry.value;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: event.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(event.icon, size: 20, color: event.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.date ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: event.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineEvent {
  final IconData icon;
  final String title;
  final String? date;
  final String status;
  final Color color;

  const _TimelineEvent({
    required this.icon,
    required this.title,
    required this.date,
    required this.status,
    required this.color,
  });
}

class _SuggestedDepartment {
  final String name;
  final String reason;

  const _SuggestedDepartment(this.name, this.reason);
}

DateTime _dateFor(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime(1970);
  }
  final trimmed = value.length > 10 ? value.substring(0, 10) : value;
  return DateTime.tryParse(trimmed) ?? DateTime(1970);
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
