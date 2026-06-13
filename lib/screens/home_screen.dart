import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A3C5E), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.local_hospital, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'PHLMS Medical Center',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kozhikode, Kerala',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              _emergencyBanner(),
              const SizedBox(height: 20),
              _sectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                      label: 'Book\nAppointment',
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.search,
                      color: const Color(0xFF00897B),
                      label: 'Find\nDoctor',
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.science,
                      color: Colors.purple,
                      label: 'Lab\nReports',
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _sectionTitle('Our Departments'),
              const SizedBox(height: 4),
              Text(
                'Tap a department to find available doctors',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: const [
                  _DepartmentCard(
                    name: 'Cardiology',
                    icon: Icons.favorite,
                    color: Color(0xFFE53935),
                  ),
                  _DepartmentCard(
                    name: 'Neurology',
                    icon: Icons.psychology,
                    color: Color(0xFF8E24AA),
                  ),
                  _DepartmentCard(
                    name: 'Orthopedics',
                    icon: Icons.accessibility_new,
                    color: Color(0xFF1E88E5),
                  ),
                  _DepartmentCard(
                    name: 'Pediatrics',
                    icon: Icons.child_care,
                    color: Color(0xFFFF8F00),
                  ),
                  _DepartmentCard(
                    name: 'Dermatology',
                    icon: Icons.face,
                    color: Color(0xFFD81B60),
                  ),
                  _DepartmentCard(
                    name: 'General Med',
                    icon: Icons.medical_services,
                    color: Color(0xFF00897B),
                  ),
                  _DepartmentCard(
                    name: 'Oncology',
                    icon: Icons.biotech,
                    color: Color(0xFF6D4C41),
                  ),
                  _DepartmentCard(
                    name: 'Ophthalmology',
                    icon: Icons.visibility,
                    color: Color(0xFF039BE5),
                  ),
                  _DepartmentCard(
                    name: 'ENT',
                    icon: Icons.hearing,
                    color: Color(0xFF43A047),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _sectionTitle('Why Choose Us'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: const [
                  _BenefitCard(
                    icon: Icons.access_time_filled,
                    title: '24/7 Emergency',
                    subtitle: 'Round the clock care',
                  ),
                  _BenefitCard(
                    icon: Icons.people,
                    title: '200+ Specialists',
                    subtitle: 'Expert doctors',
                  ),
                  _BenefitCard(
                    icon: Icons.folder_shared,
                    title: 'Digital Records',
                    subtitle: 'All records online',
                  ),
                  _BenefitCard(
                    icon: Icons.directions_car,
                    title: 'GPS Ambulance',
                    subtitle: 'Fast response fleet',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _loginCta(context),
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'PHLMS Medical Center · Kozhikode · © 2025',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3C5E),
      ),
    );
  }

  Widget _emergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.sos, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '24/7 Emergency: 108',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse('tel:108');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              foregroundColor: Colors.white,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  Widget _loginCta(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3C5E), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Ready to get started?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Login to book appointments, view records, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, size: 34, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _DepartmentCard({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/department_doctors',
          arguments: name,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
