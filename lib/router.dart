import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/admin_shell.dart';
import '../features/doctor_shell.dart';
import '../features/lab_shell.dart';
import '../features/patient_shell.dart';
import '../features/pharmacy_shell.dart';
import '../features/staff_shell.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../services/hospital_api.dart';
import '../shared/widgets.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;
      final user = auth.currentUser;

      if (location == '/hospital_dashboard') return '/admin';
      if (location == '/doctor_dashboard') return '/doctor';
      if (location == '/patient_dashboard') return '/patient';
      if (location == '/lab_dashboard') return '/lab';
      if (location == '/pharmacy_dashboard') return '/pharmacy';
      if (location == '/staff_dashboard') return '/staff';

      if (user == null) {
        return location == '/login' ? null : '/login';
      }

      final role = user.role;
      if (location == '/' || location == '/login') {
        return role.path;
      }

      return _canAccess(location, role) ? null : role.path;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (_, state) {
          return const _HomeScreen();
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, state) {
          return const LoginScreen();
        },
      ),
      ShellRoute(
        builder: (_, state, child) {
          return PatientShell(
            child: state.uri.path == '/patient'
                ? const SizedBox.shrink()
                : child,
          );
        },
        routes: [
          GoRoute(
            path: '/patient',
            name: 'patient',
            builder: (_, state) {
              return const SizedBox.shrink();
            },
            routes: [
              GoRoute(
                path: 'book',
                name: 'patient_book',
                builder: (_, state) {
                  return PatientBookingScreen(
                    initialOnline:
                        state.uri.queryParameters['online'] == 'true',
                  );
                },
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (_, state, child) {
          return DoctorShell(
            child: state.uri.path == '/doctor'
                ? const SizedBox.shrink()
                : child,
          );
        },
        routes: [
          GoRoute(
            path: '/doctor',
            name: 'doctor',
            builder: (_, state) {
              return const SizedBox.shrink();
            },
            routes: [
              GoRoute(
                path: 'patient/:id',
                name: 'doctor_patient',
                builder: (_, state) {
                  return PatientDetailScreen(
                    patientId: int.parse(state.pathParameters['id']!),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/staff',
        name: 'staff',
        builder: (_, state) {
          return StaffShell();
        },
      ),
      GoRoute(
        path: '/lab',
        name: 'lab',
        builder: (_, state) {
          return LabShell();
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, state) {
          return AdminShell();
        },
      ),
      GoRoute(
        path: '/pharmacy',
        name: 'pharmacy',
        builder: (_, state) {
          return PharmacyShell();
        },
      ),
    ],
  );
}

bool _canAccess(String location, UserRole role) {
  if (location.startsWith('/doctor/patient/')) {
    return role == UserRole.doctor;
  }
  switch (location) {
    case '/patient':
    case '/patient/book':
      return role == UserRole.patient;
    case '/doctor':
      return role == UserRole.doctor;
    case '/staff':
      return role == UserRole.staff;
    case '/admin':
      return role == UserRole.admin;
    case '/lab':
      return role == UserRole.lab;
    case '/pharmacy':
      return role == UserRole.pharmacy;
    default:
      return true;
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PHLM - Hospital Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HomeCard(
            title: 'Hospital Admin',
            subtitle: 'Manage doctors, staff, patients, beds and audits',
            icon: Icons.admin_panel_settings,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => context.go('/admin'),
          ),
          _HomeCard(
            title: 'Doctor',
            subtitle: 'View appointments, patients and prescriptions',
            icon: Icons.medical_services,
            color: Colors.green,
            onTap: () => context.go('/doctor'),
          ),
          _HomeCard(
            title: 'Patient',
            subtitle: 'Book appointments, view reports and bills',
            icon: Icons.person,
            color: Colors.orange,
            onTap: () => context.go('/patient'),
          ),
          _HomeCard(
            title: 'Lab',
            subtitle: 'Process lab reports and queue entries',
            icon: Icons.science,
            color: Colors.purple,
            onTap: () => context.go('/lab'),
          ),
          _HomeCard(
            title: 'Pharmacy',
            subtitle: 'Dispense medicines and manage stock',
            icon: Icons.local_pharmacy,
            color: Colors.red,
            onTap: () => context.go('/pharmacy'),
          ),
          _HomeCard(
            title: 'Staff',
            subtitle: 'Handle tasks, beds and hospital queue',
            icon: Icons.badge,
            color: Colors.teal,
            onTap: () => context.go('/staff'),
          ),
        ],
      ),
    );
  }
}

class PatientDetailScreen extends StatelessWidget {
  final int patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Details')),
      body: Center(
        child: AppCard(child: Text('Patient $patientId details placeholder')),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _RoleShell extends StatefulWidget {
  final UserRole role;
  final String title;
  final List<_ShellTab> tabs;

  const _RoleShell({
    required this.role,
    required this.title,
    required this.tabs,
  });

  @override
  State<_RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<_RoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tab = widget.tabs[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
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
      body: _bodyFor(tab.label),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: widget.tabs
            .map(
              (tab) =>
                  NavigationDestination(icon: Icon(tab.icon), label: tab.label),
            )
            .toList(),
      ),
    );
  }

  Widget _bodyFor(String label) {
    switch (widget.role) {
      case UserRole.patient:
        return _patientBody(label);
      case UserRole.doctor:
        return _doctorBody(label);
      case UserRole.staff:
        return _staffBody(label);
      case UserRole.admin:
        return _adminBody(label);
      case UserRole.lab:
        return _labBody(label);
      case UserRole.pharmacy:
        return _pharmacyBody(label);
      case UserRole.guest:
        return const SizedBox.shrink();
    }
  }

  Widget _patientBody(String label) {
    switch (label) {
      case 'Overview':
        return _DashboardContent(
          cards: const [
            _SummaryCard(
              title: 'Appointments',
              value: 'Live',
              icon: Icons.calendar_today,
            ),
            _SummaryCard(title: 'Reports', value: 'Live', icon: Icons.science),
            _SummaryCard(
              title: 'Bills',
              value: 'Live',
              icon: Icons.receipt_long,
            ),
          ],
          sections: [
            _FutureSection(
              title: 'Appointments',
              future: () => HospitalApi().getAppointments(),
            ),
            _FutureSection(
              title: 'Lab Reports',
              future: () => HospitalApi().getLabReports(),
            ),
            _FutureSection(
              title: 'Bills',
              future: () => HospitalApi().getBills(),
            ),
          ],
        );
      case 'Appointments':
        return _FutureSection(
          title: 'Appointments',
          future: () => HospitalApi().getAppointments(),
        );
      case 'Reports':
        return _FutureSection(
          title: 'Lab Reports',
          future: () => HospitalApi().getLabReports(),
        );
      case 'Bills':
        return _FutureSection(
          title: 'Bills',
          future: () => HospitalApi().getBills(),
        );
      default:
        return _FutureSection(
          title: 'Hospitals',
          future: () => HospitalApi().getHospitals(),
        );
    }
  }

  Widget _doctorBody(String label) {
    switch (label) {
      case 'Overview':
        return _DashboardContent(
          cards: const [
            _SummaryCard(
              title: 'Appointments',
              value: 'Live',
              icon: Icons.calendar_today,
            ),
            _SummaryCard(title: 'Patients', value: 'Live', icon: Icons.people),
            _SummaryCard(
              title: 'Prescriptions',
              value: 'Live',
              icon: Icons.medication,
            ),
          ],
          sections: [
            _FutureSection(
              title: 'Appointments',
              future: () => HospitalApi().getAppointments(),
            ),
            _FutureSection(
              title: 'Patients',
              future: () => HospitalApi().getDoctors(),
            ),
            _FutureSection(
              title: 'Prescriptions',
              future: () => HospitalApi().getPrescriptions(),
            ),
          ],
        );
      case 'Appointments':
        return _FutureSection(
          title: 'Appointments',
          future: () => HospitalApi().getAppointments(),
        );
      case 'Patients':
        return _FutureSection(
          title: 'Doctors',
          future: () => HospitalApi().getDoctors(),
        );
      default:
        return _FutureSection(
          title: 'Prescriptions',
          future: () => HospitalApi().getPrescriptions(),
        );
    }
  }

  Widget _staffBody(String label) {
    switch (label) {
      case 'Overview':
        return _DashboardContent(
          cards: const [
            _SummaryCard(title: 'Tasks', value: 'Live', icon: Icons.task_alt),
            _SummaryCard(title: 'Beds', value: 'Live', icon: Icons.hotel),
            _SummaryCard(title: 'Queue', value: 'Live', icon: Icons.queue),
          ],
          sections: [
            _FutureSection(
              title: 'Tasks',
              future: () => HospitalApi().getStaffTasks(),
            ),
            _FutureSection(
              title: 'Beds',
              future: () => HospitalApi().getBeds(),
            ),
            _FutureSection(
              title: 'Queue',
              future: () => HospitalApi().getQueueEntries(),
            ),
          ],
        );
      case 'Tasks':
        return _FutureSection(
          title: 'Tasks',
          future: () => HospitalApi().getStaffTasks(),
        );
      case 'Beds':
        return _FutureSection(
          title: 'Beds',
          future: () => HospitalApi().getBeds(),
        );
      default:
        return _FutureSection(
          title: 'Queue',
          future: () => HospitalApi().getQueueEntries(),
        );
    }
  }

  Widget _adminBody(String label) {
    switch (label) {
      case 'Overview':
        return _DashboardContent(
          cards: const [
            _SummaryCard(
              title: 'Departments',
              value: 'Live',
              icon: Icons.business,
            ),
            _SummaryCard(title: 'Staff', value: 'Live', icon: Icons.badge),
            _SummaryCard(title: 'Audit', value: 'Live', icon: Icons.history),
          ],
          sections: [
            _FutureSection(
              title: 'Departments',
              future: () => HospitalApi().getDepartments(),
            ),
            _FutureSection(
              title: 'Staff',
              future: () => HospitalApi().getDoctors(),
            ),
            _FutureSection(
              title: 'Audit',
              future: () => HospitalApi().getAuditEntries(),
            ),
          ],
        );
      case 'Departments':
        return _FutureSection(
          title: 'Departments',
          future: () => HospitalApi().getDepartments(),
        );
      case 'Staff':
        return _FutureSection(
          title: 'Staff',
          future: () => HospitalApi().getDoctors(),
        );
      default:
        return _FutureSection(
          title: 'Audit',
          future: () => HospitalApi().getAuditEntries(),
        );
    }
  }

  Widget _labBody(String label) {
    switch (label) {
      case 'Overview':
        return _DashboardContent(
          cards: const [
            _SummaryCard(title: 'Reports', value: 'Live', icon: Icons.science),
            _SummaryCard(title: 'Queue', value: 'Live', icon: Icons.queue),
            _SummaryCard(title: 'Stats', value: 'Live', icon: Icons.insights),
          ],
          sections: [
            _FutureSection(
              title: 'Reports',
              future: () => HospitalApi().getLabReports(),
            ),
            _FutureSection(
              title: 'Queue',
              future: () => HospitalApi().getQueueEntries(),
            ),
            _FutureSection(
              title: 'Stats',
              future: () => HospitalApi().getStats(),
            ),
          ],
        );
      case 'Reports':
        return _FutureSection(
          title: 'Reports',
          future: () => HospitalApi().getLabReports(),
        );
      case 'Queue':
        return _FutureSection(
          title: 'Queue',
          future: () => HospitalApi().getQueueEntries(),
        );
      default:
        return _FutureSection(
          title: 'Stats',
          future: () => HospitalApi().getStats(),
        );
    }
  }

  Widget _pharmacyBody(String label) {
    switch (label) {
      case 'Overview':
        return _DashboardContent(
          cards: const [
            _SummaryCard(
              title: 'Prescriptions',
              value: 'Live',
              icon: Icons.medication,
            ),
            _SummaryCard(
              title: 'Medicines',
              value: 'Live',
              icon: Icons.local_pharmacy,
            ),
            _SummaryCard(
              title: 'Bills',
              value: 'Live',
              icon: Icons.receipt_long,
            ),
          ],
          sections: [
            _FutureSection(
              title: 'Prescriptions',
              future: () => HospitalApi().getPrescriptions(),
            ),
            _FutureSection(
              title: 'Medicines',
              future: () => HospitalApi().getMedicines(),
            ),
            _FutureSection(
              title: 'Bills',
              future: () => HospitalApi().getBills(),
            ),
          ],
        );
      case 'Prescriptions':
        return _FutureSection(
          title: 'Prescriptions',
          future: () => HospitalApi().getPrescriptions(),
        );
      case 'Medicines':
        return _FutureSection(
          title: 'Medicines',
          future: () => HospitalApi().getMedicines(),
        );
      default:
        return _FutureSection(
          title: 'Bills',
          future: () => HospitalApi().getBills(),
        );
    }
  }
}

class _DashboardContent extends StatelessWidget {
  final List<_SummaryCard> cards;
  final List<_FutureSection> sections;

  const _DashboardContent({required this.cards, required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 180,
                      child: _SummaryCardView(card: card),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        ...sections,
      ],
    );
  }
}

class _SummaryCard {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _SummaryCardView extends StatelessWidget {
  final _SummaryCard card;

  const _SummaryCardView({required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(card.icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(card.title, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              card.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureSection<T> extends StatelessWidget {
  final String title;
  final Future<List<T>> Function() future;

  const _FutureSection({required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _SectionHeader(title: title),
        const SizedBox(height: 8),
        FutureBuilder<List<T>>(
          future: future(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to load ${title.toLowerCase()}.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              );
            }

            final items = snapshot.data ?? <T>[];
            if (items.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No $title available.'),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, previous) => const Divider(height: 1),
              itemBuilder: (_, index) => _DataTile(item: items[index]),
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _DataTile<T> extends StatelessWidget {
  final T item;

  const _DataTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _iconFor(item),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(_titleFor(item)),
        subtitle: Text(_subtitleFor(item)),
        trailing: _statusFor(item) == null
            ? null
            : Chip(label: Text(_statusFor(item)!)),
      ),
    );
  }
}

String _titleFor(dynamic item) {
  if (item is Hospital) return item.name ?? 'Hospital ${item.id}';
  if (item is Department) return item.name ?? 'Department ${item.id}';
  if (item is Doctor) return item.specialty ?? 'Doctor ${item.id}';
  if (item is Appointment) return 'Appointment ${item.id}';
  if (item is LabReport) return item.title ?? 'Lab Report ${item.id}';
  if (item is Prescription) return 'Prescription ${item.id}';
  if (item is Bill) return item.billNumber ?? 'Bill ${item.id}';
  if (item is Medicine) return item.name ?? 'Medicine ${item.id}';
  if (item is AppNotification) return item.message ?? 'Notification ${item.id}';
  if (item is QueueEntry) return 'Token ${item.tokenNumber}';
  if (item is StaffTask) return item.title ?? 'Task ${item.id}';
  if (item is Bed) return item.bedNumber ?? 'Bed ${item.id}';
  if (item is Ambulance) return item.vehicleNumber ?? 'Ambulance ${item.id}';
  if (item is AuditEntry) return item.action ?? 'Audit ${item.id}';
  if (item is Stat) return item.metricKey ?? 'Stat ${item.id}';
  if (item is DeptLoad) return 'Dept Load ${item.id}';
  return item.toString();
}

String _subtitleFor(dynamic item) {
  if (item is Hospital) return item.address ?? '';
  if (item is Department) return item.description ?? '';
  if (item is Doctor) {
    return '${item.department ?? ''} • ${item.available ? 'Available' : 'Unavailable'}';
  }
  if (item is Appointment) return '${item.date ?? ''} ${item.time ?? ''}';
  if (item is LabReport) return item.testType ?? '';
  if (item is Prescription) return item.notes ?? '';
  if (item is Bill) return '${item.status} • ${item.amount.toStringAsFixed(2)}';
  if (item is Medicine) return '${item.stockQuantity} in stock';
  if (item is AppNotification) return item.type ?? '';
  if (item is QueueEntry) return item.status ?? '';
  if (item is StaffTask) return item.description ?? '';
  if (item is Bed) return item.status ?? '';
  if (item is Ambulance) return item.status ?? '';
  if (item is AuditEntry) return item.entityType ?? '';
  if (item is Stat) return item.metricValue.toStringAsFixed(2);
  if (item is DeptLoad) {
    return '${item.patientCount} patients • ${item.doctorCount} doctors';
  }
  return '';
}

String? _statusFor(dynamic item) {
  if (item is Doctor) return item.available ? 'Available' : 'Unavailable';
  if (item is Appointment) return item.status;
  if (item is Bill) return item.status;
  if (item is Medicine) return item.isAvailable ? 'Available' : 'Out of Stock';
  if (item is AppNotification) return item.isRead ? 'Read' : 'Unread';
  if (item is QueueEntry) return item.status;
  if (item is StaffTask) return item.status;
  if (item is Bed) return item.status;
  if (item is Ambulance) return item.status;
  return null;
}

IconData _iconFor(dynamic item) {
  if (item is Hospital) return Icons.business;
  if (item is Department) return Icons.business_center;
  if (item is Doctor) return Icons.medical_services;
  if (item is Appointment) return Icons.calendar_today;
  if (item is LabReport) return Icons.science;
  if (item is Prescription) return Icons.medication;
  if (item is Bill) return Icons.receipt_long;
  if (item is Medicine) return Icons.local_pharmacy;
  if (item is AppNotification) return Icons.notifications;
  if (item is QueueEntry) return Icons.queue;
  if (item is StaffTask) return Icons.task_alt;
  if (item is Bed) return Icons.hotel;
  if (item is Ambulance) return Icons.local_hospital;
  if (item is AuditEntry) return Icons.history;
  if (item is Stat) return Icons.insights;
  if (item is DeptLoad) return Icons.insights;
  return Icons.info_outline;
}

class _ShellTab {
  final String label;
  final IconData icon;

  const _ShellTab({required this.label, required this.icon});
}
