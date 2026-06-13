import '../database/database_helper.dart';
import '../models/models.dart';
import 'mock_api.dart';

class HospitalApi {
  static final HospitalApi _instance = HospitalApi._internal();
  factory HospitalApi() => _instance;
  HospitalApi._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final MockApi _mock = MockApi();

  Future<List<T>> _delayed<T>(
    Future<List<T>> Function() fetch, [
    Future<List<T>> Function()? fallback,
  ]) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final items = await fetch();
    if (items.isEmpty && fallback != null) {
      return fallback();
    }
    return items;
  }

  Future<List<Hospital>> getHospitals() =>
      _delayed(_db.getAllHospitals, _mock.getHospitals);
  Future<List<Department>> getDepartments() =>
      _delayed(_db.getAllDepartments, _mock.getDepartments);
  Future<List<Doctor>> getDoctors() =>
      _delayed(_db.getAllDoctors, _mock.getDoctors);
  Future<List<Appointment>> getAppointments() =>
      _delayed(_db.getAllAppointments, _mock.getAppointments);
  Future<List<LabReport>> getLabReports() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT lr.id, lo.patient_id, lo.doctor_id, 1 AS hospital_id,
             r.test_name AS title, r.test_name AS test_type,
             r.result_value AS result, r.recorded_at AS uploaded_at
      FROM lab_reports lr
      JOIN lab_results r ON r.id = lr.result_id
      JOIN lab_orders lo ON lo.id = r.order_id
      WHERE lr.patient_visible = 1
    ''');
    if (rows.isEmpty) return _mock.getLabReports();
    return rows.map((row) => LabReport.fromMap(row)).toList();
  }

  Future<List<Prescription>> getPrescriptions() =>
      _delayed(_db.getAllPrescriptions, _mock.getPrescriptions);
  Future<List<Bill>> getBills() => _delayed(_db.getAllBills, _mock.getBills);
  Future<List<Medicine>> getMedicines() => _delayed(_db.getAllMedicines);
  Future<List<AppNotification>> getNotifications() =>
      _delayed(_db.getAllNotifications);
  Future<List<QueueEntry>> getQueueEntries() =>
      _delayed(_db.getAllQueueEntries);
  Future<List<StaffTask>> getStaffTasks() => _delayed(_db.getAllStaffTasks);
  Future<List<Bed>> getBeds() => _delayed(_db.getAllBeds);
  Future<List<Ambulance>> getAmbulances() => _delayed(_db.getAllAmbulances);
  Future<List<AuditEntry>> getAuditEntries() =>
      _delayed(_db.getAllAuditEntries);
  Future<List<Stat>> getStats() => _delayed(_db.getAllStats);
  Future<List<DeptLoad>> getDeptLoads() => _delayed(_db.getAllDeptLoads);

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?> args = const [],
  ]) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final db = await _db.database;
    return db.rawQuery(sql, args);
  }
}
