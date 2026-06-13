import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../shared/widgets.dart';
import 'role_scaffold.dart';

enum _LabTab { orders, process, reports, tools }

class LabShell extends StatefulWidget {
  const LabShell({super.key});

  @override
  State<LabShell> createState() => _LabShellState();
}

class _LabShellState extends State<LabShell> {
  final _db = DatabaseHelper();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tab = _LabTab.values[_index];
    return Scaffold(
      appBar: buildRoleAppBar('LABORATORY', context),
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
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.mediation), label: 'Process'),
          NavigationDestination(
            icon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services),
            label: 'Tools',
          ),
        ],
      ),
    );
  }

  Widget _bodyFor(_LabTab tab) {
    switch (tab) {
      case _LabTab.orders:
        return _OrdersTab(db: _db);
      case _LabTab.process:
        return _ProcessTab(db: _db);
      case _LabTab.reports:
        return _ReportsTab(db: _db);
      case _LabTab.tools:
        return _ToolsTab();
    }
  }
}

class _OrdersTab extends StatefulWidget {
  final DatabaseHelper db;

  const _OrdersTab({required this.db});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.db.rawQuery('''
              SELECT lo.*,
                COALESCE(p.first_name || ' ' || p.last_name, 'Patient ' || p.id) AS patient_name,
                COALESCE(d.name, 'Doctor ' || d.id) AS doctor_name
              FROM lab_orders lo
              LEFT JOIN patients p ON p.id = lo.patient_id
              LEFT JOIN doctors d ON d.id = lo.doctor_id
              WHERE lo.status = 'Pending'
            '''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snapshot.data ?? [];
              final orders = rows.map(_orderFromRow).toList()
                ..sort(
                  (a, b) => _priorityRank(
                    a.priority,
                  ).compareTo(_priorityRank(b.priority)),
                );
              if (orders.isEmpty) {
                return const Text('No pending lab orders.');
              }
              return Column(
                children: orders
                    .map((order) => _OrderCard(db: widget.db, order: order))
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  LabOrder _orderFromRow(Map<String, dynamic> row) {
    final patientName = row['patient_name'] as String?;
    final doctorName = row['doctor_name'] as String?;
    return LabOrder(
      id: row['id'] as int?,
      doctorId: row['doctor_id'] as int?,
      patientId: row['patient_id'] as int?,
      tests: _decodeTests(row['tests_json'] as String?),
      priority: row['priority'] as String? ?? 'Routine',
      status: row['status'] as String? ?? 'Pending',
      createdAt: row['created_at'] as String? ?? '',
      instructions: [
        row['instructions'] as String?,
        patientName != null ? 'Patient: $patientName' : null,
        doctorName != null ? 'Doctor: $doctorName' : null,
      ].whereType<String>().join('\n'),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DatabaseHelper db;
  final LabOrder order;

  const _OrderCard({required this.db, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AppAvatar(
          label: 'Lab',
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text('Order #${order.id} • ${order.tests.join(', ')}'),
        subtitle: Text('${order.createdAt} • ${order.priority}'),
        trailing: _PriorityBadge(priority: order.priority),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _OrderDetailScreen(db: db, order: order),
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priority == 'Stat'
        ? Colors.red
        : priority == 'Urgent'
        ? Colors.orange
        : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OrderDetailScreen extends StatelessWidget {
  final DatabaseHelper db;
  final LabOrder order;

  const _OrderDetailScreen({required this.db, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildRoleAppBar('Order #${order.id}', context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Patient Info'),
                Text(order.instructions ?? 'No patient details available.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Tests Requested'),
                ...order.tests.map((test) => Text('• $test')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await db.updateLabOrder(
                      order.copyWith(
                        status: 'Processing',
                        currentStep: 1,
                        lastStepAt: DateTime.now().toIso8601String(),
                      ),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Accept Order'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reject(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final reason = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await db.updateLabOrder(
                order.copyWith(status: 'Rejected', instructions: reason.text),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reason.dispose();
  }
}

class _ProcessTab extends StatefulWidget {
  final DatabaseHelper db;

  const _ProcessTab({required this.db});

  @override
  State<_ProcessTab> createState() => _ProcessTabState();
}

class _ProcessTabState extends State<_ProcessTab> {
  final Map<int, Map<String, TextEditingController>> _forms = {};

  @override
  void dispose() {
    for (final form in _forms.values) {
      for (final controller in form.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<List<LabOrder>>(
          future: widget.db.getAllLabOrders(status: 'Processing'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) return const Text('No processing orders.');
            return Column(
              children: orders
                  .map(
                    (order) => _ProcessingOrderCard(
                      db: widget.db,
                      order: order,
                      controllers: _controllersFor(order),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Map<String, TextEditingController> _controllersFor(LabOrder order) {
    return _forms.putIfAbsent(order.id ?? 0, () {
      final controllers = <String, TextEditingController>{};
      for (final test in order.tests) {
        controllers['${test}_value'] = TextEditingController();
        controllers['${test}_unit'] = TextEditingController(
          text: _defaultUnit(test),
        );
        controllers['${test}_range'] = TextEditingController(
          text: _defaultRange(test),
        );
      }
      return controllers;
    });
  }
}

class _ProcessingOrderCard extends StatelessWidget {
  final DatabaseHelper db;
  final LabOrder order;
  final Map<String, TextEditingController> controllers;

  const _ProcessingOrderCard({
    required this.db,
    required this.order,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order #${order.id} • ${order.tests.join(', ')}'),
          const SizedBox(height: 12),
          _StepIndicators(step: order.currentStep),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await db.updateLabOrder(
                order.copyWith(
                  currentStep: order.currentStep < 2
                      ? order.currentStep + 1
                      : order.currentStep,
                  lastStepAt: DateTime.now().toIso8601String(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Update Step'),
          ),
          const SizedBox(height: 12),
          ...order.tests.map(
            (test) => _ResultEntry(test: test, controllers: controllers),
          ),
          ElevatedButton.icon(
            onPressed: () => _submitResults(context, order),
            icon: const Icon(Icons.save),
            label: const Text('Submit Results'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitResults(BuildContext context, LabOrder order) async {
    final actorId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    final now = DateTime.now().toIso8601String();
    for (final test in order.tests) {
      final value = controllers['${test}_value']!.text;
      if (value.isEmpty) continue;
      final unit = controllers['${test}_unit']!.text;
      final range = controllers['${test}_range']!.text;
      await db.insertLabResult(
        LabResult(
          orderId: order.id,
          testName: test,
          resultValue: value,
          unit: unit,
          referenceRange: range,
          flagged: _isFlagged(value, range),
          recordedBy: actorId,
          recordedAt: now,
        ),
      );
    }
    await db.updateLabOrder(
      order.copyWith(status: 'Completed', currentStep: 2, lastStepAt: now),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Results submitted.')));
  }
}

class _StepIndicators extends StatelessWidget {
  final int step;

  const _StepIndicators({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Sample Collected', 'Analyzing', 'Results Ready'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = step >= index;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: active
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[index], style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      }),
    );
  }
}

class _ResultEntry extends StatelessWidget {
  final String test;
  final Map<String, TextEditingController> controllers;

  const _ResultEntry({required this.test, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(test, style: Theme.of(context).textTheme.titleSmall),
            TextField(
              controller: controllers['${test}_value'],
              decoration: const InputDecoration(labelText: 'Result value'),
            ),
            TextField(
              controller: controllers['${test}_unit'],
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            TextField(
              controller: controllers['${test}_range'],
              decoration: const InputDecoration(labelText: 'Reference range'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsTab extends StatefulWidget {
  final DatabaseHelper db;

  const _ReportsTab({required this.db});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
          decoration: const InputDecoration(
            labelText: 'Search reports',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        ToggleButtons(
          isSelected: [
            'Today',
            'This Week',
            'All',
          ].map((filter) => filter == _filter).toList(),
          onPressed: (index) =>
              setState(() => _filter = ['Today', 'This Week', 'All'][index]),
          children: const [Text('Today'), Text('This Week'), Text('All')],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.db.rawQuery('''
            SELECT lr.id, lr.result_id, lr.published, lr.published_at, lr.patient_visible,
                   r.test_name, r.result_value, r.unit, r.reference_range, r.flagged, r.recorded_at,
                   COALESCE(p.first_name || ' ' || p.last_name, 'Patient ' || p.id) AS patient_name
            FROM lab_reports lr
            JOIN lab_results r ON r.id = lr.result_id
            JOIN lab_orders lo ON lo.id = r.order_id
            LEFT JOIN patients p ON p.id = lo.patient_id
            WHERE lo.status = 'Completed'
          '''),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];
            final reports = rows
                .where((row) => _matchesFilter(row) && _matchesQuery(row))
                .map(_ReportRow.fromMap)
                .toList();
            if (reports.isEmpty) return const Text('No completed lab reports.');
            return Column(
              children: reports
                  .map((report) => _ReportCard(db: widget.db, report: report))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  bool _matchesFilter(Map<String, dynamic> row) {
    final date = row['recorded_at'] as String? ?? '';
    final now = DateTime.now();
    if (_filter == 'Today') return date.startsWith(_formatDate(now));
    if (_filter == 'This Week') {
      final recorded = DateTime.tryParse(date);
      return recorded != null && now.difference(recorded).inDays <= 7;
    }
    return true;
  }

  bool _matchesQuery(Map<String, dynamic> row) {
    if (_query.isEmpty) return true;
    final haystack = '${row['patient_name'] ?? ''} ${row['test_name'] ?? ''}'
        .toLowerCase();
    return haystack.contains(_query);
  }
}

class _ReportCard extends StatelessWidget {
  final DatabaseHelper db;
  final _ReportRow report;

  const _ReportCard({required this.db, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          report.flagged ? Icons.warning : Icons.check_circle,
          color: report.flagged ? Colors.red : Colors.green,
        ),
        title: Text('${report.patientName} • ${report.testName}'),
        subtitle: Text(
          '${report.resultValue} ${report.unit} • Ref ${report.referenceRange}',
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            if (report.id != null) {
              await db.updateLabReport(
                LabReportRecord(
                  id: report.id,
                  resultId: report.resultId,
                  published: true,
                  publishedAt: DateTime.now().toIso8601String(),
                  patientVisible: true,
                ),
              );
            } else {
              await db.insertLabReport(
                LabReportRecord(
                  resultId: report.resultId,
                  published: true,
                  publishedAt: DateTime.now().toIso8601String(),
                  patientVisible: true,
                ),
              );
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Report published.')));
          },
          child: const Text('Publish'),
        ),
      ),
    );
  }
}

class _ReportRow {
  final int? id;
  final int? resultId;
  final bool published;
  final String? publishedAt;
  final bool patientVisible;
  final String testName;
  final String resultValue;
  final String unit;
  final String referenceRange;
  final bool flagged;
  final String recordedAt;
  final String patientName;

  _ReportRow({
    this.id,
    this.resultId,
    this.published = false,
    this.publishedAt,
    this.patientVisible = false,
    required this.testName,
    required this.resultValue,
    required this.unit,
    required this.referenceRange,
    this.flagged = false,
    required this.recordedAt,
    required this.patientName,
  });

  factory _ReportRow.fromMap(Map<String, dynamic> row) => _ReportRow(
    id: row['id'] as int?,
    resultId: row['result_id'] as int?,
    published: row['published'] == 1,
    publishedAt: row['published_at'] as String?,
    patientVisible: row['patient_visible'] == 1,
    testName: row['test_name'] as String? ?? '',
    resultValue: row['result_value'] as String? ?? '',
    unit: row['unit'] as String? ?? '',
    referenceRange: row['reference_range'] as String? ?? '',
    flagged: row['flagged'] == 1,
    recordedAt: row['recorded_at'] as String? ?? '',
    patientName: row['patient_name'] as String? ?? '',
  );

  _ReportRow copyWith({
    int? id,
    int? resultId,
    bool? published,
    String? publishedAt,
    bool? patientVisible,
  }) {
    return _ReportRow(
      id: id ?? this.id,
      resultId: resultId ?? this.resultId,
      published: published ?? this.published,
      publishedAt: publishedAt ?? this.publishedAt,
      patientVisible: patientVisible ?? this.patientVisible,
      testName: testName,
      resultValue: resultValue,
      unit: unit,
      referenceRange: referenceRange,
      flagged: flagged,
      recordedAt: recordedAt,
      patientName: patientName,
    );
  }
}

class _ToolsTab extends StatelessWidget {
  const _ToolsTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Catalogue'),
              Tab(text: 'Home Collection'),
              Tab(text: 'Packages'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 520,
            child: TabBarView(
              children: [_TestCatalogue(), _HomeCollection(), _TestPackages()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCatalogue extends StatefulWidget {
  const _TestCatalogue();

  @override
  State<_TestCatalogue> createState() => _TestCatalogueState();
}

class _TestCatalogueState extends State<_TestCatalogue> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tests = _testCatalogue
        .where((test) => test['name'].toString().toLowerCase().contains(_query))
        .toList();
    return Column(
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
          decoration: const InputDecoration(labelText: 'Search tests'),
        ),
        ...tests.map(
          (test) => ListTile(
            title: Text(test['name']!),
            subtitle: Text(
              '${test['code']} • ${test['sample']} • TAT ${test['tat']} • Ref ${test['range']}',
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeCollection extends StatelessWidget {
  const _HomeCollection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _homeCollections
          .map(
            (request) => ListTile(
              title: Text(request['address']!),
              subtitle: Text('${request['time']} • ${request['collector']}'),
            ),
          )
          .toList(),
    );
  }
}

class _TestPackages extends StatelessWidget {
  const _TestPackages();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _packages
          .map(
            (package) => ListTile(
              title: Text(package['name']!),
              subtitle: Text('${package['tests']} • ₹${package['price']}'),
            ),
          )
          .toList(),
    );
  }
}

List<Map<String, String>> get _testCatalogue => [
  {
    'name': 'CBC',
    'code': 'HEM001',
    'sample': 'Blood',
    'tat': '2 hrs',
    'range': 'See lab range',
  },
  {
    'name': 'Lipid Profile',
    'code': 'BIO010',
    'sample': 'Blood',
    'tat': '4 hrs',
    'range': 'LDL <100 mg/dL',
  },
  {
    'name': 'Blood Sugar',
    'code': 'BIO001',
    'sample': 'Blood',
    'tat': '1 hr',
    'range': '70-100 mg/dL',
  },
  {
    'name': 'LFT',
    'code': 'BIO020',
    'sample': 'Blood',
    'tat': '3 hrs',
    'range': 'ALT 7-56 U/L',
  },
];

List<Map<String, String>> get _homeCollections => [
  {'address': '12 Lake Road', 'time': '08:00 AM', 'collector': 'Rahul'},
  {'address': '45 Garden Avenue', 'time': '10:30 AM', 'collector': 'Meera'},
];

List<Map<String, String>> get _packages => [
  {
    'name': 'Full Body Checkup',
    'tests': 'CBC + Lipid + Sugar + LFT',
    'price': '1999',
  },
  {'name': 'Diabetes Care', 'tests': 'HbA1c + Sugar + Lipid', 'price': '999'},
];

List<String> _decodeTests(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const [];
  try {
    final value = jsonDecode(encoded);
    if (value is List) return value.cast<String>();
  } catch (_) {
    return encoded
        .split(',')
        .map((test) => test.trim())
        .where((test) => test.isNotEmpty)
        .toList();
  }
  return const [];
}

int _priorityRank(String priority) {
  switch (priority) {
    case 'Stat':
      return 0;
    case 'Urgent':
      return 1;
    default:
      return 2;
  }
}

String _defaultUnit(String test) {
  if (test.contains('Sugar')) return 'mg/dL';
  if (test.contains('Hemoglobin')) return 'g/dL';
  return '';
}

String _defaultRange(String test) {
  if (test.contains('Sugar')) return '70-100';
  if (test.contains('Hemoglobin')) return '12-17';
  return '';
}

bool _isFlagged(String value, String range) {
  final numeric = double.tryParse(value);
  if (numeric == null || range.isEmpty) return false;
  final parts = range
      .split('-')
      .map((part) => double.tryParse(part.trim()))
      .toList();
  if (parts.length == 2 && parts[0] != null && parts[1] != null) {
    return numeric < parts[0]! || numeric > parts[1]!;
  }
  return false;
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
