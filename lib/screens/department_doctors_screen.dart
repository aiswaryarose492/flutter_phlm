import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class DepartmentDoctorsScreen extends StatefulWidget {
  const DepartmentDoctorsScreen({super.key});

  @override
  State<DepartmentDoctorsScreen> createState() => _State();
}

class _State extends State<DepartmentDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _loading = true;
  String _departmentName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _departmentName =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loading = true);
    final db = await DatabaseHelper().database;

    final result = await db.rawQuery(
      '''
      SELECT d.id, d.specialty, d.department, d.experience,
             d.available, d.appointment_fees, d.qualification,
             d.available_start_time, d.available_end_time,
             u.first_name, u.last_name
      FROM doctors d
      JOIN users u ON d.user_id = u.id
      WHERE LOWER(d.department) = LOWER(?)
      ORDER BY d.experience DESC
    ''',
      [_departmentName],
    );

    if (!mounted) return;
    setState(() {
      _doctors = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_departmentName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No doctors available in $_departmentName',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  child: Text(
                    '${_doctors.length} doctor(s) available in $_departmentName',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _doctors.length,
                    itemBuilder: (_, i) {
                      final d = _doctors[i];
                      final name =
                          'Dr. ${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'
                              .trim();
                      final available = d['available'] == 1;
                      final fees =
                          (d['appointment_fees'] as num?)?.toDouble() ?? 0.0;
                      final initial = (d['first_name'] ?? 'D')
                          .toString()
                          .substring(0, 1);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: available
                                                ? Colors.green[50]
                                                : Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: available
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                          child: Text(
                                            available
                                                ? 'Available'
                                                : 'Unavailable',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: available
                                                  ? Colors.green[800]
                                                  : Colors.red[800],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d['specialty'] ?? _departmentName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (d['qualification'] != null)
                                      Text(
                                        d['qualification']!,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.work_outline,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${d['experience']} yrs experience',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.currency_rupee,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        Text(
                                          '${fees.toStringAsFixed(0)} / visit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (d['available_start_time'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${d['available_start_time']} – ${d['available_end_time'] ?? ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: available
                                            ? () => Navigator.pushNamed(
                                                context,
                                                '/login',
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                        ),
                                        label: const Text('Book Appointment'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
