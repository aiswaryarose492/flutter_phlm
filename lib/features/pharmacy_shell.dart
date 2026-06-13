import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../shared/widgets.dart';
import 'role_scaffold.dart';

enum _PharmacyTab { queue, inventory, orders, reports }

class PharmacyShell extends StatefulWidget {
  const PharmacyShell({super.key});

  @override
  State<PharmacyShell> createState() => _PharmacyShellState();
}

class _PharmacyShellState extends State<PharmacyShell> {
  final _db = DatabaseHelper();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tab = _PharmacyTab.values[_index];
    return Scaffold(
      appBar: buildRoleAppBar('PHARMACY', context),
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
          NavigationDestination(icon: Icon(Icons.queue), label: 'Queue'),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Reports'),
        ],
      ),
    );
  }

  Widget _bodyFor(_PharmacyTab tab) {
    switch (tab) {
      case _PharmacyTab.queue:
        return _QueueTab(db: _db);
      case _PharmacyTab.inventory:
        return _InventoryTab(db: _db);
      case _PharmacyTab.orders:
        return _OrdersTab(db: _db);
      case _PharmacyTab.reports:
        return _ReportsTab(db: _db);
    }
  }
}

class _QueueTab extends StatelessWidget {
  final DatabaseHelper db;

  const _QueueTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: db.rawQuery('''
            SELECT pr.*, ap.patient_id AS linked_patient_id,
              COALESCE(pa.first_name || ' ' || pa.last_name, 'Patient ' || pa.id) AS patient_name,
              pa.age, pa.ward, pa.opd,
              COALESCE(d.name, 'Doctor ' || d.id) AS doctor_name
            FROM prescriptions pr
            LEFT JOIN appointments ap ON ap.id = pr.appointment_id
            LEFT JOIN patients pa ON pa.id = ap.patient_id
            LEFT JOIN doctors d ON d.id = ap.doctor_id
            WHERE pr.is_dispensed = 0
            ORDER BY pr.created_at DESC
          '''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final prescriptions =
                snapshot.data?.map(_prescriptionFromRow).toList() ?? [];
            if (prescriptions.isEmpty) {
              return const Text('No prescriptions waiting to be dispensed.');
            }
            return Column(
              children: prescriptions
                  .map(
                    (prescription) =>
                        _PrescriptionCard(db: db, prescription: prescription),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

Prescription _prescriptionFromRow(Map<String, dynamic> row) {
  final patientName = row['patient_name'] as String?;
  final age = row['age'] as int?;
  final ward = row['ward'] as String?;
  final opd = row['opd'] as String?;
  return Prescription(
    id: row['id'] as int?,
    appointmentId: row['appointment_id'] as int?,
    medicines: row['medicines'] as String?,
    notes: [
      row['notes'] as String?,
      patientName != null
          ? 'Patient: $patientName${age != null ? ', Age: $age' : ''}'
          : null,
      ward != null ? 'Ward: $ward' : null,
      opd != null ? 'OPD: $opd' : null,
      row['doctor_name'] != null ? 'Doctor: ${row['doctor_name']}' : null,
    ].whereType<String>().join('\n'),
    isDispensed: row['is_dispensed'] == 1,
    createdAt: row['created_at'] as String?,
  );
}

class _PrescriptionCard extends StatelessWidget {
  final DatabaseHelper db;
  final Prescription prescription;

  const _PrescriptionCard({required this.db, required this.prescription});

  @override
  Widget build(BuildContext context) {
    final medicines = _decodePrescriptionMedicines(prescription.medicines);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AppAvatar(
          label: 'Rx',
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text('Rx #${prescription.id} • ${medicines.length} medicines'),
        subtitle: Text(
          '${prescription.createdAt} • ${prescription.notes?.split('\n').first ?? ''}',
        ),
        trailing: Icon(
          Icons.medication,
          color: Theme.of(context).colorScheme.error,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                _PrescriptionDetailScreen(db: db, prescription: prescription),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionDetailScreen extends StatefulWidget {
  final DatabaseHelper db;
  final Prescription prescription;

  const _PrescriptionDetailScreen({
    required this.db,
    required this.prescription,
  });

  @override
  State<_PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<_PrescriptionDetailScreen> {
  final Map<String, TextEditingController> _substitutes = {};

  @override
  void dispose() {
    for (final controller in _substitutes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicines = _decodePrescriptionMedicines(
      widget.prescription.medicines,
    );
    return Scaffold(
      appBar: buildRoleAppBar(
        'Prescription #${widget.prescription.id}',
        context,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Text(widget.prescription.notes ?? 'No prescription notes.'),
          ),
          const SizedBox(height: 12),
          ...medicines.map(
            (medicine) => _MedicineDispenseTile(
              db: widget.db,
              medicine: medicine,
              substituteController: _substitutes.putIfAbsent(
                medicine,
                () => TextEditingController(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _dispense(context, partial: false),
                  icon: const Icon(Icons.check),
                  label: const Text('Dispense'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _dispense(context, partial: true),
                  icon: const Icon(Icons.medication),
                  label: const Text('Partial'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _dispense(BuildContext context, {required bool partial}) async {
    final actorId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    final medicines = _decodePrescriptionMedicines(
      widget.prescription.medicines,
    );
    final available = <String>[];
    for (final medicine in medicines) {
      final stock = await _stockFor(medicine);
      if (stock.stockQuantity > 0 || partial) available.add(medicine);
    }
    final total = await _totalFor(available);
    final now = DateTime.now().toIso8601String();
    await widget.db.insertDispensingLog(
      DispensingLog(
        prescriptionId: widget.prescription.id,
        pharmacistId: actorId,
        patientId:
            widget.prescription.patientId ?? widget.prescription.appointmentId,
        medicines: available,
        dispensedAt: now,
        totalAmount: total,
      ),
    );
    for (final medicine in available) {
      final stock = await _stockFor(medicine);
      if (stock.stockQuantity > 0) {
        await widget.db.updateMedicine(
          stock.copyWith(stockQuantity: stock.stockQuantity - 1),
        );
      }
    }
    await widget.db.updatePrescription(
      widget.prescription.copyWith(isDispensed: true),
    );
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dispensing recorded.')));
  }

  Future<Medicine> _stockFor(String name) async {
    final medicines = await widget.db.getAllMedicines();
    return medicines.firstWhere(
      (medicine) => medicine.name == name,
      orElse: () =>
          Medicine(name: name, stockQuantity: 0, reorderLevel: 5, price: 0),
    );
  }

  Future<double> _totalFor(List<String> medicines) async {
    final rows = await widget.db.rawQuery(
      'SELECT SUM(price) AS total FROM medicines WHERE name IN (${List.filled(medicines.length, '?').join(',')})',
      medicines,
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

class _MedicineDispenseTile extends StatelessWidget {
  final DatabaseHelper db;
  final String medicine;
  final TextEditingController substituteController;

  const _MedicineDispenseTile({
    required this.db,
    required this.medicine,
    required this.substituteController,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medicine>>(
      future: db.getAllMedicines(),
      builder: (context, snapshot) {
        final stock = snapshot.data?.firstWhere(
          (item) => item.name == medicine,
          orElse: () =>
              Medicine(name: medicine, stockQuantity: 0, reorderLevel: 5),
        );
        final status = stock == null || stock.stockQuantity == 0
            ? 'Out of Stock'
            : stock.stockQuantity <= stock.reorderLevel
            ? 'Low Stock'
            : 'In Stock';
        final color = status == 'In Stock'
            ? Colors.green
            : status == 'Low Stock'
            ? Colors.orange
            : Colors.red;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(medicine)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (status == 'Out of Stock')
                  TextField(
                    controller: substituteController,
                    decoration: const InputDecoration(
                      labelText: 'Substitute suggestion',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InventoryTab extends StatefulWidget {
  final DatabaseHelper db;

  const _InventoryTab({required this.db});

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
          decoration: const InputDecoration(
            labelText: 'Search medicines',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['All', 'Tablet', 'Injection', 'Syrup', 'Topical']
              .map(
                (category) => FilterChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Medicine>>(
          future: widget.db.getAllMedicines(),
          builder: (context, snapshot) {
            final medicines = (snapshot.data ?? [])
                .where((medicine) => _matches(medicine))
                .toList();
            final lowStock = medicines
                .where(
                  (medicine) =>
                      medicine.stockQuantity <= medicine.reorderLevel &&
                      medicine.stockQuantity > 0,
                )
                .toList();
            final expiring = medicines
                .where((medicine) => _expiringSoon(medicine))
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlertSection(title: 'Low Stock Alerts', medicines: lowStock),
                _AlertSection(title: 'Expiring Soon', medicines: expiring),
                ...medicines.map(
                  (medicine) =>
                      _MedicineStockCard(db: widget.db, medicine: medicine),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  bool _matches(Medicine medicine) {
    final categoryMatches =
        _category == 'All' || medicine.category == _category;
    final query = _query;
    final haystack =
        '${medicine.name ?? ''} ${medicine.brand ?? ''} ${medicine.category ?? ''}'
            .toLowerCase();
    return categoryMatches && (query.isEmpty || haystack.contains(query));
  }

  bool _expiringSoon(Medicine medicine) {
    final expiry = DateTime.tryParse(medicine.expiryDate ?? '');
    return expiry != null &&
        expiry.difference(DateTime.now()).inDays <= 30 &&
        expiry.isAfter(DateTime.now());
  }
}

class _AlertSection extends StatelessWidget {
  final String title;
  final List<Medicine> medicines;

  const _AlertSection({required this.title, required this.medicines});

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          ...medicines.map(
            (medicine) => Text(
              '${medicine.name} • ${medicine.stockQuantity} ${medicine.unit ?? ''}',
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineStockCard extends StatelessWidget {
  final DatabaseHelper db;
  final Medicine medicine;

  const _MedicineStockCard({required this.db, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final color = medicine.stockQuantity == 0
        ? Colors.red
        : medicine.stockQuantity <= medicine.reorderLevel
        ? Colors.orange
        : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          child: Icon(Icons.medication, color: color),
        ),
        title: Text('${medicine.name} • ${medicine.brand ?? ''}'),
        subtitle: Text(
          '${medicine.category ?? '-'} • Stock ${medicine.stockQuantity} ${medicine.unit ?? ''} • Reorder ${medicine.reorderLevel} • ₹${medicine.price.toStringAsFixed(2)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editStock(context, medicine),
        ),
      ),
    );
  }

  Future<void> _editStock(BuildContext context, Medicine medicine) async {
    final quantity = TextEditingController(
      text: medicine.stockQuantity.toString(),
    );
    final batch = TextEditingController();
    final expiry = TextEditingController(text: medicine.expiryDate ?? '');
    final supplier = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: batch,
              decoration: const InputDecoration(labelText: 'Batch number'),
            ),
            TextField(
              controller: expiry,
              decoration: const InputDecoration(labelText: 'Expiry'),
            ),
            TextField(
              controller: supplier,
              decoration: const InputDecoration(labelText: 'Supplier'),
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
              final added = int.tryParse(quantity.text) ?? 0;
              await db.updateMedicine(
                medicine.copyWith(
                  stockQuantity: medicine.stockQuantity + added,
                  expiryDate: expiry.text,
                ),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    quantity.dispose();
    batch.dispose();
    expiry.dispose();
    supplier.dispose();
  }
}

class _OrdersTab extends StatelessWidget {
  final DatabaseHelper db;

  const _OrdersTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Home Delivery'),
              Tab(text: 'Refill Requests'),
              Tab(text: 'Prescription Upload'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 520,
            child: TabBarView(
              children: [
                _HomeDeliveryTab(db: db),
                _RefillTab(db: db),
                const _UploadTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDeliveryTab extends StatefulWidget {
  final DatabaseHelper db;

  const _HomeDeliveryTab({required this.db});

  @override
  State<_HomeDeliveryTab> createState() => _HomeDeliveryTabState();
}

class _HomeDeliveryTabState extends State<_HomeDeliveryTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeDeliveryOrder>>(
      future: widget.db.getAllHomeDeliveryOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        return Column(
          children: orders
              .map(
                (order) => ListTile(
                  title: Text(order.address),
                  subtitle: Text('${order.status} • ${order.createdAt}'),
                  trailing: ElevatedButton(
                    onPressed: order.status != 'Dispatched'
                        ? () => widget.db.updateHomeDeliveryOrder(
                            order.copyWith(
                              status: 'Dispatched',
                              dispatchedAt: DateTime.now().toIso8601String(),
                            ),
                          )
                        : null,
                    child: const Text('Mark Dispatched'),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _RefillTab extends StatelessWidget {
  final DatabaseHelper db;

  const _RefillTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RefillRequest>>(
      future: db.getAllRefillRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        return Column(
          children: requests
              .map(
                (request) => ListTile(
                  title: Text('Patient ${request.patientId}'),
                  subtitle: Text(
                    'Medicines: ${request.medicineIds.join(', ')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () => db.updateRefillRequest(
                          request.copyWith(
                            status: 'Approved',
                            processedAt: DateTime.now().toIso8601String(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => db.updateRefillRequest(
                          request.copyWith(
                            status: 'Rejected',
                            processedAt: DateTime.now().toIso8601String(),
                            reason: 'Not approved',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _UploadTab extends StatelessWidget {
  const _UploadTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No uploaded prescriptions awaiting verification.'),
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
  String _filter = 'Today';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ToggleButtons(
          isSelected: [
            'Today',
            'This Week',
            'This Month',
          ].map((filter) => filter == _filter).toList(),
          onPressed: (index) => setState(
            () => _filter = ['Today', 'This Week', 'This Month'][index],
          ),
          children: const [
            Text('Today'),
            Text('This Week'),
            Text('This Month'),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.db.rawQuery(
            'SELECT COUNT(*) AS count, COALESCE(SUM(total_amount), 0) AS revenue FROM dispensing_log',
          ),
          builder: (context, snapshot) {
            final row = snapshot.data?.first ?? {};
            return Row(
              children: [
                Expanded(
                  child: DashboardStatCard(
                    title: 'Dispensed',
                    value: (row['count'] as int? ?? 0).toString(),
                    icon: Icons.medication,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Expanded(
                  child: DashboardStatCard(
                    title: 'Revenue',
                    value: '₹${(row['revenue'] as num?)?.toDouble() ?? 0}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        AppCard(child: _TopMedicines(db: widget.db)),
        const SizedBox(height: 12),
        AppCard(child: _SupplierCost(db: widget.db)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _exportCsv(context),
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    try {
      final rows = await widget.db.getAllDispensingLogs();
      final csv = rows
          .map(
            (row) =>
                [
                      row.dispensedAt,
                      row.prescriptionId,
                      row.medicines.join('|'),
                      row.totalAmount,
                    ]
                    .map(
                      (value) => '"${value.toString().replaceAll('"', '""')}"',
                    )
                    .join(','),
          )
          .join('\n');
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'dispensing_log.csv'));
      await file.writeAsString(csv);
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

class _TopMedicines extends StatelessWidget {
  final DatabaseHelper db;

  const _TopMedicines({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.rawQuery(
        'SELECT name, COUNT(*) AS count FROM dispensing_log GROUP BY name ORDER BY count DESC LIMIT 10',
      ),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Top Medicines'),
            ...rows.map(
              (row) => _BarRow(
                label: row['name'] ?? '',
                value: (row['count'] as int? ?? 0).toDouble(),
                max: rows.fold<double>(
                  0,
                  (sum, item) =>
                      sum + ((item['count'] as int? ?? 0).toDouble()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SupplierCost extends StatelessWidget {
  final DatabaseHelper db;

  const _SupplierCost({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.rawQuery(
        'SELECT manufacturer, SUM(unit_price * stock_quantity) AS cost FROM medicines GROUP BY manufacturer',
      ),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Supplier Procurement Cost'),
            ...rows.map(
              (row) => _BarRow(
                label: row['manufacturer'] ?? '',
                value: (row['cost'] as num?)?.toDouble() ?? 0,
                max: rows.fold<double>(
                  0,
                  (sum, item) =>
                      sum + ((item['cost'] as num?)?.toDouble() ?? 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;

  const _BarRow({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(value: max == 0 ? 0 : value / max),
          ),
          Text(value.round().toString()),
        ],
      ),
    );
  }
}

List<String> _decodePrescriptionMedicines(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const [];
  try {
    final value = jsonDecode(encoded);
    if (value is List) return value.cast<String>();
  } catch (_) {
    return encoded
        .split(',')
        .map((medicine) => medicine.trim())
        .where((medicine) => medicine.isNotEmpty)
        .toList();
  }
  return const [];
}
