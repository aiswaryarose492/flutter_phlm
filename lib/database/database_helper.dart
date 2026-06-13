import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      await _connectivityCheck();
      return _database!;
    }
    _database = await _initDatabase();
    await _connectivityCheck();
    return _database!;
  }

  Future<bool> isOnline() => _isOnline();

  Future<void> _connectivityCheck() async {
    try {
      await _isOnline();
    } catch (_) {}
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'phlm_db.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?> args = const [],
  ]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  Future<void> _queueWrite({
    required String operationType,
    required String tableName,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert('pending_sync', {
      'operation_type': operationType,
      'table_name': tableName,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> insertPendingSync(PendingSync sync) async {
    final db = await database;
    return await db.insert('pending_sync', sync.toMap());
  }

  Future<List<PendingSync>> getPendingSyncItems() async {
    final db = await database;
    final maps = await db.query('pending_sync', orderBy: 'id ASC');
    return maps.map((e) => PendingSync.fromMap(e)).toList();
  }

  Future<void> markSynced(PendingSync sync) async {
    final db = await database;
    await db.update(
      'pending_sync',
      {'synced_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sync.id],
    );
  }

  Future<int> insertHealthReward(HealthReward reward) async {
    final db = await database;
    return await db.insert('health_rewards', reward.toMap());
  }

  Future<List<HealthReward>> getHealthRewards({int? patientId}) async {
    final db = await database;
    final maps = patientId == null
        ? await db.query('health_rewards', orderBy: 'earned_at DESC')
        : await db.query(
            'health_rewards',
            where: 'patient_id = ?',
            whereArgs: [patientId],
            orderBy: 'earned_at DESC',
          );
    return maps.map((e) => HealthReward.fromMap(e)).toList();
  }

  Future<int> getHealthRewardPoints({int? patientId}) async {
    final rows = await rawQuery(
      patientId == null
          ? 'SELECT COALESCE(SUM(points), 0) AS points FROM health_rewards'
          : 'SELECT COALESCE(SUM(points), 0) AS points FROM health_rewards WHERE patient_id = ?',
      patientId == null ? const [] : [patientId],
    );
    final value = rows.first['points'];
    return value is int ? value : (value as num?)?.toInt() ?? 0;
  }

  Future<void> ensureMergeTables() async {
    final db = await database;
    try {
      await db.execute(
        'ALTER TABLE hospitals ADD COLUMN emergency_number TEXT',
      );
      await db.execute('ALTER TABLE patients ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN photo_path TEXT');
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN follow_up_date TEXT',
      );
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN reminder_sent INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE users ADD COLUMN is_blocked INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE users ADD COLUMN last_login TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN linked_entity_id INTEGER');
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN appointment_fees REAL DEFAULT 0.00',
      );
      await db.execute('ALTER TABLE doctors ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE doctors ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE doctors ADD COLUMN email TEXT');
      await db.execute(
        'ALTER TABLE doctors ADD COLUMN status TEXT DEFAULT \'Active\'',
      );
      await db.execute(
        'ALTER TABLE departments ADD COLUMN head_doctor_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE departments ADD COLUMN avg_wait_minutes REAL DEFAULT 0.00',
      );
      await db.execute(
        'ALTER TABLE departments ADD COLUMN status TEXT DEFAULT \'Active\'',
      );
      await db.execute('ALTER TABLE staff ADD COLUMN shift_pattern TEXT');
      await db.execute('ALTER TABLE staff ADD COLUMN joining_date TEXT');
      await db.execute(
        'ALTER TABLE staff ADD COLUMN status TEXT DEFAULT \'Active\'',
      );
      await db.execute('ALTER TABLE ambulances ADD COLUMN dispatch_time TEXT');
      await db.execute('ALTER TABLE ambulances ADD COLUMN destination TEXT');
      await db.execute('ALTER TABLE ambulances ADD COLUMN eta TEXT');
      await db.execute(
        'ALTER TABLE medicines ADD COLUMN stock_qty INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE medicines ADD COLUMN brand TEXT');
      await db.execute('ALTER TABLE medicines ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE medicines ADD COLUMN unit TEXT');
      await db.execute('ALTER TABLE medicines ADD COLUMN expiry_date TEXT');
      await db.execute(
        'ALTER TABLE medicines ADD COLUMN price REAL DEFAULT 0.00',
      );
      await db.execute(
        'ALTER TABLE medicines ADD COLUMN prescription_only INTEGER DEFAULT 1',
      );
    } catch (_) {}
    await _createAppWideTables(db);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS family_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        name TEXT,
        relation TEXT,
        age INTEGER,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient_vitals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        bp_systolic INTEGER,
        bp_diastolic INTEGER,
        spo2 INTEGER,
        weight REAL,
        recorded_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lab_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER,
        patient_id INTEGER,
        tests TEXT,
        priority TEXT DEFAULT 'Routine',
        status TEXT DEFAULT 'Pending',
        created_at TEXT,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        who INTEGER,
        action TEXT,
        target_user_id INTEGER,
        timestamp TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS departments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        name TEXT,
        description TEXT,
        floor TEXT,
        phone TEXT,
        head_doctor_id INTEGER,
        avg_wait_minutes REAL DEFAULT 0.00,
        status TEXT DEFAULT 'Active',
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dispensing_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id INTEGER,
        pharmacist_id INTEGER,
        patient_id INTEGER,
        medicines_json TEXT,
        dispensed_at TEXT,
        total_amount REAL DEFAULT 0.00,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id),
        FOREIGN KEY (pharmacist_id) REFERENCES users (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS home_delivery_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        prescription_id INTEGER,
        address TEXT,
        status TEXT DEFAULT 'Pending',
        created_at TEXT,
        dispatched_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS refill_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        medicine_ids_json TEXT,
        status TEXT DEFAULT 'Pending',
        requested_at TEXT,
        processed_at TEXT,
        reason TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        assigned_to INTEGER,
        title TEXT,
        description TEXT,
        status TEXT DEFAULT 'Pending',
        due_date TEXT,
        priority TEXT DEFAULT 'Normal',
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (assigned_to) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER,
        patient_id INTEGER,
        bed_number TEXT,
        shift TEXT,
        FOREIGN KEY (staff_id) REFERENCES users (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lab_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER,
        patient_id INTEGER,
        tests_json TEXT,
        priority TEXT DEFAULT 'Routine',
        status TEXT DEFAULT 'Pending',
        created_at TEXT,
        instructions TEXT,
        current_step INTEGER DEFAULT 0,
        last_step_at TEXT,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lab_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        test_name TEXT,
        result_value TEXT,
        unit TEXT,
        reference_range TEXT,
        flagged INTEGER DEFAULT 0,
        recorded_by INTEGER,
        recorded_at TEXT,
        FOREIGN KEY (order_id) REFERENCES lab_orders (id),
        FOREIGN KEY (recorded_by) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lab_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result_id INTEGER,
        published INTEGER DEFAULT 0,
        published_at TEXT,
        patient_visible INTEGER DEFAULT 0,
        FOREIGN KEY (result_id) REFERENCES lab_results (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vitals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        recorded_by INTEGER,
        timestamp TEXT,
        bp_sys INTEGER,
        bp_dia INTEGER,
        spo2 INTEGER,
        temp REAL,
        pulse INTEGER,
        weight REAL,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (recorded_by) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS handover_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER,
        shift TEXT,
        summary TEXT,
        created_at TEXT,
        shift_complete INTEGER DEFAULT 0,
        FOREIGN KEY (staff_id) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS internal_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        channel TEXT,
        sender_id INTEGER,
        text TEXT,
        timestamp TEXT,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER,
        clock_in TEXT,
        clock_out TEXT,
        FOREIGN KEY (staff_id) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS discharge_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        bed_id INTEGER,
        bed_number TEXT,
        discharged_at TEXT,
        notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (bed_id) REFERENCES beds (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS doctor_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        doctor_id INTEGER,
        note TEXT,
        created_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (doctor_id) REFERENCES doctors (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER,
        patient_id INTEGER,
        bed_number TEXT,
        shift TEXT,
        FOREIGN KEY (staff_id) REFERENCES users (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vitals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        recorded_by INTEGER,
        timestamp TEXT,
        bp_sys INTEGER,
        bp_dia INTEGER,
        spo2 INTEGER,
        temp REAL,
        pulse INTEGER,
        weight REAL,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (recorded_by) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS handover_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER,
        shift TEXT,
        summary TEXT,
        created_at TEXT,
        shift_complete INTEGER DEFAULT 0,
        FOREIGN KEY (staff_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS internal_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        channel TEXT,
        sender_id INTEGER,
        text TEXT,
        timestamp TEXT,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff_attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER,
        clock_in TEXT,
        clock_out TEXT,
        FOREIGN KEY (staff_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS discharge_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        bed_id INTEGER,
        bed_number TEXT,
        discharged_at TEXT,
        notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (bed_id) REFERENCES beds (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS doctor_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        doctor_id INTEGER,
        note TEXT,
        created_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (doctor_id) REFERENCES doctors (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS beds(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        ward_id INTEGER,
        bed_number TEXT,
        status TEXT DEFAULT 'Available',
        patient_id INTEGER,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (ward_id) REFERENCES wards (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT,
        entity_type TEXT,
        entity_id INTEGER,
        details TEXT,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        metric_key TEXT,
        metric_value REAL DEFAULT 0.00,
        recorded_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dept_loads(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        department_id INTEGER,
        patient_count INTEGER DEFAULT 0,
        doctor_count INTEGER DEFAULT 0,
        occupancy_rate REAL DEFAULT 0.00,
        recorded_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (department_id) REFERENCES departments (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await _createAppWideTables(db);
    }
  }

  Future<void> _createAppWideTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sync(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT,
        table_name TEXT,
        payload_json TEXT,
        created_at TEXT,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_rewards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        points INTEGER DEFAULT 0,
        reason TEXT,
        earned_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
  }

  Future _onCreate(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        email TEXT,
        password TEXT,
        first_name TEXT,
        last_name TEXT,
        is_hospital_admin INTEGER DEFAULT 0,
        is_doctor INTEGER DEFAULT 0,
        is_patient INTEGER DEFAULT 0,
        is_lab INTEGER DEFAULT 0,
        is_pharmacy INTEGER DEFAULT 0,
        is_staff_member INTEGER DEFAULT 0,
        is_blocked INTEGER DEFAULT 0,
        last_login TEXT,
        linked_entity_id INTEGER
      )
    ''');

    // Hospital table
    await db.execute('''
      CREATE TABLE hospitals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        address TEXT,
        max_leave_days INTEGER DEFAULT 12,
        extra_leave_deduction REAL DEFAULT 0.00,
        latitude REAL,
        longitude REAL,
        allowed_ip_address TEXT,
        emergency_number TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Doctor table
    await db.execute('''
      CREATE TABLE doctors(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        hospital_id INTEGER,
        specialty TEXT,
        department TEXT,
        image_path TEXT,
        qualification TEXT,
        experience INTEGER DEFAULT 0,
        bio TEXT,
        available INTEGER DEFAULT 1,
        available_days TEXT,
        available_start_time TEXT,
        available_end_time TEXT,
        break_start_time TEXT,
        break_end_time TEXT,
        max_appointments_per_day INTEGER DEFAULT 10,
        appointment_fees REAL DEFAULT 0.00,
        salary REAL DEFAULT 0.00,
        salary_frequency TEXT DEFAULT 'Monthly',
        name TEXT,
        phone TEXT,
        email TEXT,
        status TEXT DEFAULT 'Active',
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    // Patient table
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        hospital_id INTEGER,
        phone TEXT,
        date_of_birth TEXT,
        gender TEXT DEFAULT 'Other',
        address TEXT,
        name TEXT,
        photo_path TEXT,
        water_goal INTEGER DEFAULT 8,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE family_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        name TEXT,
        relation TEXT,
        age INTEGER,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    // Appointment table
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER,
        patient_id INTEGER,
        date TEXT,
        time TEXT,
        symptoms TEXT,
        is_online INTEGER DEFAULT 0,
        meet_link TEXT,
        appointment_fees REAL DEFAULT 0.00,
        status TEXT DEFAULT 'Pending',
        follow_up_date TEXT,
        reminder_sent INTEGER DEFAULT 0,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE patient_vitals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        bp_systolic INTEGER,
        bp_diastolic INTEGER,
        spo2 INTEGER,
        weight REAL,
        recorded_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dispensing_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id INTEGER,
        pharmacist_id INTEGER,
        patient_id INTEGER,
        medicines_json TEXT,
        dispensed_at TEXT,
        total_amount REAL DEFAULT 0.00,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id),
        FOREIGN KEY (pharmacist_id) REFERENCES users (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE home_delivery_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        prescription_id INTEGER,
        address TEXT,
        status TEXT DEFAULT 'Pending',
        created_at TEXT,
        dispatched_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE refill_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        medicine_ids_json TEXT,
        status TEXT DEFAULT 'Pending',
        requested_at TEXT,
        processed_at TEXT,
        reason TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lab_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        test_name TEXT,
        result_value TEXT,
        unit TEXT,
        reference_range TEXT,
        flagged INTEGER DEFAULT 0,
        recorded_by INTEGER,
        recorded_at TEXT,
        FOREIGN KEY (order_id) REFERENCES lab_orders (id),
        FOREIGN KEY (recorded_by) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lab_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result_id INTEGER,
        published INTEGER DEFAULT 0,
        published_at TEXT,
        patient_visible INTEGER DEFAULT 0,
        FOREIGN KEY (result_id) REFERENCES lab_results (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lab_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER,
        patient_id INTEGER,
        tests_json TEXT,
        priority TEXT DEFAULT 'Routine',
        status TEXT DEFAULT 'Pending',
        created_at TEXT,
        instructions TEXT,
        current_step INTEGER DEFAULT 0,
        last_step_at TEXT,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    // Staff table
    await db.execute('''
      CREATE TABLE staff(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        hospital_id INTEGER,
        role TEXT DEFAULT 'Nurse',
        phone TEXT,
        image_path TEXT,
        duty_date TEXT,
        duty_start TEXT,
        duty_end TEXT,
        shift_pattern TEXT,
        joining_date TEXT,
        status TEXT DEFAULT 'Active',
        notes TEXT,
        salary REAL DEFAULT 0.00,
        salary_frequency TEXT DEFAULT 'Monthly',
        available_days TEXT,
        available_start_time TEXT,
        available_end_time TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    // LabWorker table
    await db.execute('''
      CREATE TABLE lab_workers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        hospital_id INTEGER,
        phone TEXT,
        image_path TEXT,
        salary REAL DEFAULT 0.00,
        salary_frequency TEXT DEFAULT 'Monthly',
        available_days TEXT,
        available_start_time TEXT,
        available_end_time TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    // PharmacyWorker table
    await db.execute('''
      CREATE TABLE pharmacy_workers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        hospital_id INTEGER,
        phone TEXT,
        image_path TEXT,
        salary REAL DEFAULT 0.00,
        salary_frequency TEXT DEFAULT 'Monthly',
        available_days TEXT,
        available_start_time TEXT,
        available_end_time TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    // LabReport table
    await db.execute('''
      CREATE TABLE lab_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        doctor_id INTEGER,
        hospital_id INTEGER,
        title TEXT,
        test_type TEXT,
        file_path TEXT,
        patient_upload TEXT,
        patient_uploaded_at TEXT,
        result TEXT,
        result_file TEXT,
        result_uploaded_at TEXT,
        reviewed_by INTEGER,
        uploaded_at TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (doctor_id) REFERENCES doctors (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    // Prescription table
    await db.execute('''
      CREATE TABLE prescriptions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointment_id INTEGER,
        medicines TEXT,
        notes TEXT,
        is_dispensed INTEGER DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id)
      )
    ''');

    // Reminder table
    await db.execute('''
      CREATE TABLE reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        type TEXT,
        message TEXT,
        time TEXT,
        last_taken TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    // LeaveRequest table
    await db.execute('''
      CREATE TABLE leave_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER,
        leave_type TEXT,
        start_date TEXT,
        end_date TEXT,
        reason TEXT,
        status TEXT DEFAULT 'Pending',
        applied_at TEXT,
        reviewed_by INTEGER,
        reviewed_at TEXT,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id)
      )
    ''');

    // Ward table
    await db.execute('''
      CREATE TABLE wards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        ward_number TEXT,
        ward_type TEXT DEFAULT 'General',
        floor TEXT DEFAULT '1',
        total_beds INTEGER DEFAULT 10,
        occupied_beds INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    // PatientAdmission table
    await db.execute('''
      CREATE TABLE patient_admissions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        hospital_id INTEGER,
        ward_id INTEGER,
        bed_number TEXT,
        admission_reason TEXT,
        admitting_doctor_id INTEGER,
        admission_date TEXT,
        discharge_date TEXT,
        status TEXT DEFAULT 'Admitted',
        is_serious INTEGER DEFAULT 0,
        treatment_plan TEXT,
        total_bill REAL DEFAULT 0.00,
        bill_paid REAL DEFAULT 0.00,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (ward_id) REFERENCES wards (id),
        FOREIGN KEY (admitting_doctor_id) REFERENCES doctors (id)
      )
    ''');

    // Medicine table
    await db.execute('''
      CREATE TABLE medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        name TEXT,
        generic_name TEXT,
        medicine_type TEXT,
        manufacturer TEXT,
        brand TEXT,
        category TEXT,
        stock_quantity INTEGER DEFAULT 0,
        stock_qty INTEGER DEFAULT 0,
        unit TEXT,
        reorder_level INTEGER DEFAULT 10,
        expiry_date TEXT,
        price REAL DEFAULT 0.00,
        prescription_only INTEGER DEFAULT 1,
        unit_price REAL DEFAULT 0.00,
        is_available INTEGER DEFAULT 1,
        is_external INTEGER DEFAULT 0,
        description TEXT,
        dosage_instructions TEXT,
        side_effects TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    // Notification table
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipient_id INTEGER,
        message TEXT,
        type TEXT DEFAULT 'General',
        is_read INTEGER DEFAULT 0,
        created_at TEXT,
        link TEXT,
        FOREIGN KEY (recipient_id) REFERENCES users (id)
      )
    ''');

    // EmergencyCase table
    await db.execute('''
      CREATE TABLE emergency_cases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        patient_name TEXT,
        symptoms TEXT,
        severity TEXT,
        assigned_to INTEGER,
        status TEXT DEFAULT 'Open',
        created_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (assigned_to) REFERENCES users (id)
      )
    ''');

    // Ambulance table
    await db.execute('''
      CREATE TABLE ambulances(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        vehicle_number TEXT UNIQUE,
        vehicle_type TEXT DEFAULT 'Basic Life Support',
        status TEXT DEFAULT 'Available',
        driver_name TEXT,
        driver_phone TEXT,
        driver_license TEXT,
        equipment_list TEXT,
        last_maintenance TEXT,
        next_maintenance TEXT,
        current_assignment INTEGER,
        dispatch_time TEXT,
        destination TEXT,
        eta TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (current_assignment) REFERENCES patient_admissions (id)
      )
    ''');

    // AmbulanceCall table
    await db.execute('''
      CREATE TABLE ambulance_calls(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        ambulance_id INTEGER,
        call_type TEXT,
        patient_name TEXT,
        pickup_location TEXT,
        contact_number TEXT,
        emergency_type TEXT,
        called_at TEXT,
        dispatched_at TEXT,
        arrived_at TEXT,
        completed_at TEXT,
        status TEXT DEFAULT 'Pending',
        notes TEXT,
        alarm_acknowledged INTEGER DEFAULT 0,
        acknowledged_by INTEGER,
        acknowledged_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (ambulance_id) REFERENCES ambulances (id)
      )
    ''');

    // PrescribedMedicine table
    await db.execute('''
      CREATE TABLE prescribed_medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id INTEGER,
        medicine_id INTEGER,
        medicine_name TEXT,
        dosage TEXT,
        frequency TEXT,
        duration TEXT,
        instructions TEXT,
        is_external_purchase INTEGER DEFAULT 0,
        is_dispensed INTEGER DEFAULT 0,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id),
        FOREIGN KEY (medicine_id) REFERENCES medicines (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        who INTEGER,
        action TEXT,
        target_user_id INTEGER,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE departments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        name TEXT,
        description TEXT,
        floor TEXT,
        phone TEXT,
        head_doctor_id INTEGER,
        avg_wait_minutes REAL DEFAULT 0.00,
        status TEXT DEFAULT 'Active',
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bills(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        hospital_id INTEGER,
        bill_number TEXT,
        amount REAL DEFAULT 0.00,
        paid_amount REAL DEFAULT 0.00,
        status TEXT DEFAULT 'Pending',
        created_at TEXT,
        due_date TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE queue_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        department_id INTEGER,
        patient_id INTEGER,
        doctor_id INTEGER,
        token_number INTEGER DEFAULT 0,
        status TEXT DEFAULT 'Waiting',
        created_at TEXT,
        called_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (department_id) REFERENCES departments (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (doctor_id) REFERENCES doctors (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE staff_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        assigned_to INTEGER,
        title TEXT,
        description TEXT,
        status TEXT DEFAULT 'Pending',
        due_date TEXT,
        priority TEXT DEFAULT 'Normal',
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (assigned_to) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE beds(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        ward_id INTEGER,
        bed_number TEXT,
        status TEXT DEFAULT 'Available',
        patient_id INTEGER,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (ward_id) REFERENCES wards (id),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT,
        entity_type TEXT,
        entity_id INTEGER,
        details TEXT,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        metric_key TEXT,
        metric_value REAL DEFAULT 0.00,
        recorded_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dept_loads(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_id INTEGER,
        department_id INTEGER,
        patient_count INTEGER DEFAULT 0,
        doctor_count INTEGER DEFAULT 0,
        occupancy_rate REAL DEFAULT 0.00,
        recorded_at TEXT,
        FOREIGN KEY (hospital_id) REFERENCES hospitals (id),
        FOREIGN KEY (department_id) REFERENCES departments (id)
      )
    ''');

    // StaffHealthStatus table
    await db.execute('''
      CREATE TABLE staff_health_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER,
        date TEXT,
        water_intake INTEGER DEFAULT 0,
        is_on_duty INTEGER DEFAULT 0,
        is_present INTEGER DEFAULT 0,
        shift_start TEXT,
        UNIQUE(worker_id, date),
        FOREIGN KEY (worker_id) REFERENCES users (id)
      )
    ''');

    // DailyHealthStatus table
    await db.execute('''
      CREATE TABLE daily_health_status(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER,
        date TEXT,
        water_intake INTEGER DEFAULT 0,
        meditation_done INTEGER DEFAULT 0,
        healthy_food INTEGER DEFAULT 0,
        step_count INTEGER DEFAULT 0,
        UNIQUE(patient_id, date),
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    // WorkLog table
    await db.execute('''
      CREATE TABLE work_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_id INTEGER,
        date TEXT,
        start_time TEXT,
        end_time TEXT,
        FOREIGN KEY (doctor_id) REFERENCES doctors (id)
      )
    ''');
  }

  // ==================== CRUD METHODS ====================

  // User CRUD
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((e) => User.fromMap(e)).toList();
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> insertAuditLog({
    int? who,
    required String action,
    int? targetUserId,
  }) async {
    final db = await database;
    return await db.insert('audit_log', {
      'who': who,
      'action': action,
      'target_user_id': targetUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AuditEntry>> getAllAuditLogs() async {
    final db = await database;
    final maps = await db.query('audit_log', orderBy: 'timestamp DESC');
    return maps.map((e) {
      return AuditEntry(
        id: e['id'] as int?,
        userId: e['who'] as int?,
        action: e['action'] as String?,
        entityId: e['target_user_id'] as int?,
        createdAt: e['timestamp'] as String?,
      );
    }).toList();
  }

  // Hospital CRUD
  Future<int> insertHospital(Hospital hospital) async {
    final db = await database;
    return await db.insert('hospitals', hospital.toMap());
  }

  Future<List<Hospital>> getAllHospitals() async {
    final db = await database;
    final maps = await db.query('hospitals');
    return maps.map((e) => Hospital.fromMap(e)).toList();
  }

  // Doctor CRUD
  Future<int> insertDoctor(Doctor doctor) async {
    final db = await database;
    return await db.insert('doctors', doctor.toMap());
  }

  Future<List<Doctor>> getAllDoctors() async {
    final db = await database;
    final maps = await db.query('doctors');
    return maps.map((e) => Doctor.fromMap(e)).toList();
  }

  Future<int> updateDoctor(Doctor doctor) async {
    final db = await database;
    return await db.update(
      'doctors',
      doctor.toMap(),
      where: 'id = ?',
      whereArgs: [doctor.id],
    );
  }

  Future<Doctor?> getDoctorByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'doctors',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Doctor.fromMap(maps.first);
  }

  // Patient CRUD
  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final maps = await db.query('patients');
    return maps.map((e) => Patient.fromMap(e)).toList();
  }

  Future<Patient?> getPatientByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<List<Patient>> getPatientsByHospitalId(int hospitalId) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'hospital_id = ?',
      whereArgs: [hospitalId],
    );
    return maps.map((e) => Patient.fromMap(e)).toList();
  }

  Future<int> insertFamilyMember(FamilyMember member) async {
    final db = await database;
    return await db.insert('family_members', member.toMap());
  }

  Future<List<FamilyMember>> getFamilyMembers({int? patientId}) async {
    final db = await database;
    final maps = patientId == null
        ? await db.query('family_members')
        : await db.query(
            'family_members',
            where: 'patient_id = ?',
            whereArgs: [patientId],
          );
    return maps.map((e) => FamilyMember.fromMap(e)).toList();
  }

  Future<int> insertPatientVital(PatientVital vital) async {
    final db = await database;
    final result = await db.insert('patient_vitals', vital.toMap());
    if (await _isOnline() == false) {
      await _queueWrite(
        operationType: 'insert',
        tableName: 'patient_vitals',
        payload: vital.toMap(),
      );
    }
    return result;
  }

  Future<List<PatientVital>> getPatientVitals({int? patientId}) async {
    final db = await database;
    final maps = patientId == null
        ? await db.query('patient_vitals', orderBy: 'recorded_at DESC')
        : await db.query(
            'patient_vitals',
            where: 'patient_id = ?',
            whereArgs: [patientId],
            orderBy: 'recorded_at DESC',
          );
    return maps.map((e) => PatientVital.fromMap(e)).toList();
  }

  Future<List<LabOrder>> getLabOrders({int? doctorId, int? patientId}) async {
    final db = await database;
    var where = <String>[];
    final args = <Object?>[];
    if (doctorId != null) {
      where.add('doctor_id = ?');
      args.add(doctorId);
    }
    if (patientId != null) {
      where.add('patient_id = ?');
      args.add(patientId);
    }
    final maps = await db.query(
      'lab_orders',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );
    return maps.map((e) => LabOrder.fromMap(e)).toList();
  }

  Future<int> updateAppointmentFollowUp({
    required int id,
    String? followUpDate,
    bool? reminderSent,
    String? status,
  }) async {
    final db = await database;
    final data = <String, Object?>{};
    if (followUpDate != null) data['follow_up_date'] = followUpDate;
    if (reminderSent != null) data['reminder_sent'] = reminderSent ? 1 : 0;
    if (status != null) data['status'] = status;
    final result = await db.update(
      'appointments',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (await _isOnline() == false) {
      await _queueWrite(
        operationType: 'update',
        tableName: 'appointments',
        payload: {'id': id, ...data},
      );
    }
    return result;
  }

  Future<int> deleteFamilyMember(int id) async {
    final db = await database;
    return await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }

  // Appointment CRUD
  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    final result = await db.insert('appointments', appointment.toMap());
    if (await _isOnline() == false) {
      await _queueWrite(
        operationType: 'insert',
        tableName: 'appointments',
        payload: appointment.toMap(),
      );
    }
    return result;
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final maps = await db.query('appointments');
    return maps.map((e) => Appointment.fromMap(e)).toList();
  }

  Future<int> insertBill(Bill bill) async {
    final db = await database;
    return await db.insert('bills', bill.toMap());
  }

  Future<List<Bill>> getAllBills() async {
    final db = await database;
    final maps = await db.query('bills');
    return maps.map((e) => Bill.fromMap(e)).toList();
  }

  Future<int> insertQueueEntry(QueueEntry entry) async {
    final db = await database;
    return await db.insert('queue_entries', entry.toMap());
  }

  Future<List<QueueEntry>> getAllQueueEntries() async {
    final db = await database;
    final maps = await db.query('queue_entries');
    return maps.map((e) => QueueEntry.fromMap(e)).toList();
  }

  // Prescription CRUD
  Future<int> insertPrescription(Prescription prescription) async {
    final db = await database;
    final result = await db.insert('prescriptions', prescription.toMap());
    if (await _isOnline() == false) {
      await _queueWrite(
        operationType: 'insert',
        tableName: 'prescriptions',
        payload: prescription.toMap(),
      );
    }
    return result;
  }

  Future<List<Prescription>> getAllPrescriptions() async {
    final db = await database;
    final maps = await db.query('prescriptions');
    return maps.map((e) => Prescription.fromMap(e)).toList();
  }

  // Lab CRUD
  Future<int> insertLabOrder(LabOrder order) async {
    final db = await database;
    return await db.insert('lab_orders', order.toMap());
  }

  Future<List<LabOrder>> getAllLabOrders({String? status}) async {
    final db = await database;
    final maps = status == null
        ? await db.query('lab_orders', orderBy: 'created_at DESC')
        : await db.query(
            'lab_orders',
            where: 'status = ?',
            whereArgs: [status],
            orderBy: 'created_at DESC',
          );
    return maps.map((e) => LabOrder.fromMap(e)).toList();
  }

  Future<int> updateLabOrder(LabOrder order) async {
    final db = await database;
    return await db.update(
      'lab_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> insertLabResult(LabResult result) async {
    final db = await database;
    return await db.insert('lab_results', result.toMap());
  }

  Future<List<LabResult>> getLabResultsByOrder(int orderId) async {
    final db = await database;
    final maps = await db.query(
      'lab_results',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return maps.map((e) => LabResult.fromMap(e)).toList();
  }

  Future<List<LabReportRecord>> getLabReportsByResult(int resultId) async {
    final db = await database;
    final maps = await db.query(
      'lab_reports',
      where: 'result_id = ?',
      whereArgs: [resultId],
    );
    return maps.map((e) => LabReportRecord.fromMap(e)).toList();
  }

  Future<int> updateLabReport(LabReportRecord report) async {
    final db = await database;
    return await db.update(
      'lab_reports',
      report.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  Future<int> updatePrescription(Prescription prescription) async {
    final db = await database;
    return await db.update(
      'prescriptions',
      prescription.toMap(),
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
  }

  Future<int> insertDispensingLog(DispensingLog log) async {
    final db = await database;
    return await db.insert('dispensing_log', log.toMap());
  }

  Future<List<DispensingLog>> getAllDispensingLogs() async {
    final db = await database;
    final maps = await db.query('dispensing_log', orderBy: 'dispensed_at DESC');
    return maps.map((e) => DispensingLog.fromMap(e)).toList();
  }

  Future<int> insertHomeDeliveryOrder(HomeDeliveryOrder order) async {
    final db = await database;
    return await db.insert('home_delivery_orders', order.toMap());
  }

  Future<List<HomeDeliveryOrder>> getAllHomeDeliveryOrders() async {
    final db = await database;
    final maps = await db.query(
      'home_delivery_orders',
      orderBy: 'created_at DESC',
    );
    return maps.map((e) => HomeDeliveryOrder.fromMap(e)).toList();
  }

  Future<int> updateHomeDeliveryOrder(HomeDeliveryOrder order) async {
    final db = await database;
    return await db.update(
      'home_delivery_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> insertRefillRequest(RefillRequest request) async {
    final db = await database;
    return await db.insert('refill_requests', request.toMap());
  }

  Future<List<RefillRequest>> getAllRefillRequests() async {
    final db = await database;
    final maps = await db.query(
      'refill_requests',
      orderBy: 'requested_at DESC',
    );
    return maps.map((e) => RefillRequest.fromMap(e)).toList();
  }

  Future<int> updateRefillRequest(RefillRequest request) async {
    final db = await database;
    return await db.update(
      'refill_requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  // LabReport CRUD
  Future<int> insertLabReport(LabReportRecord report) async {
    final db = await database;
    return await db.insert('lab_reports', report.toMap());
  }

  Future<List<LabReportRecord>> getAllLabReports() async {
    final db = await database;
    final maps = await db.query('lab_reports');
    return maps.map((e) => LabReportRecord.fromMap(e)).toList();
  }

  // Medicine CRUD
  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return await db.insert('medicines', medicine.toMap());
  }

  Future<List<Medicine>> getAllMedicines() async {
    final db = await database;
    final maps = await db.query('medicines');
    return maps.map((e) => Medicine.fromMap(e)).toList();
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final db = await database;
    return await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  // Reminder CRUD
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final maps = await db.query('reminders');
    return maps.map((e) => Reminder.fromMap(e)).toList();
  }

  // Notification CRUD
  Future<int> insertNotification(Notification notification) async {
    final db = await database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<Notification>> getAllNotifications() async {
    final db = await database;
    final maps = await db.query('notifications');
    return maps.map((e) => Notification.fromMap(e)).toList();
  }

  // Ward CRUD
  Future<int> insertWard(Ward ward) async {
    final db = await database;
    return await db.insert('wards', ward.toMap());
  }

  Future<List<Ward>> getAllWards() async {
    final db = await database;
    final maps = await db.query('wards');
    return maps.map((e) => Ward.fromMap(e)).toList();
  }

  // PatientAdmission CRUD
  Future<int> insertPatientAdmission(PatientAdmission admission) async {
    final db = await database;
    return await db.insert('patient_admissions', admission.toMap());
  }

  Future<List<PatientAdmission>> getAllPatientAdmissions() async {
    final db = await database;
    final maps = await db.query('patient_admissions');
    return maps.map((e) => PatientAdmission.fromMap(e)).toList();
  }

  // EmergencyCase CRUD
  Future<int> insertEmergencyCase(EmergencyCase emergency) async {
    final db = await database;
    return await db.insert('emergency_cases', emergency.toMap());
  }

  Future<List<EmergencyCase>> getAllEmergencyCases() async {
    final db = await database;
    final maps = await db.query('emergency_cases');
    return maps.map((e) => EmergencyCase.fromMap(e)).toList();
  }

  // Ambulance CRUD
  Future<int> insertAmbulance(Ambulance ambulance) async {
    final db = await database;
    return await db.insert('ambulances', ambulance.toMap());
  }

  Future<List<Ambulance>> getAllAmbulances() async {
    final db = await database;
    final maps = await db.query('ambulances');
    return maps.map((e) => Ambulance.fromMap(e)).toList();
  }

  Future<int> updateLeaveRequestStatus({
    required int id,
    required String status,
  }) async {
    final db = await database;
    return await db.update(
      'leave_requests',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateAmbulance({
    required int id,
    required String status,
    String? dispatchTime,
    String? destination,
    String? eta,
  }) async {
    final db = await database;
    return await db.update(
      'ambulances',
      {
        'status': status,
        'dispatch_time': dispatchTime,
        'destination': destination,
        'eta': eta,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertDepartment(Department department) async {
    final db = await database;
    return await db.insert('departments', department.toMap());
  }

  Future<List<Department>> getAllDepartments() async {
    final db = await database;
    final maps = await db.query('departments');
    return maps.map((e) => Department.fromMap(e)).toList();
  }

  Future<int> updateDepartment(Department department) async {
    final db = await database;
    return await db.update(
      'departments',
      department.toMap(),
      where: 'id = ?',
      whereArgs: [department.id],
    );
  }

  Future<List<StaffTask>> getAllStaffTasks() async {
    final db = await database;
    final maps = await db.query('staff_tasks');
    return maps.map((e) => StaffTask.fromMap(e)).toList();
  }

  Future<int> insertAdminStaff(AdminStaff staff) async {
    final db = await database;
    return await db.insert('staff', staff.toMap());
  }

  Future<List<AdminStaff>> getAllAdminStaff() async {
    final db = await database;
    final maps = await db.query('staff');
    return maps.map((e) => AdminStaff.fromMap(e)).toList();
  }

  Future<int> insertStaffTask(StaffTask task) async {
    final db = await database;
    return await db.insert('staff_tasks', task.toMap());
  }

  Future<int> insertBed(Bed bed) async {
    final db = await database;
    return await db.insert('beds', bed.toMap());
  }

  Future<List<Bed>> getAllBeds() async {
    final db = await database;
    final maps = await db.query('beds');
    return maps.map((e) => Bed.fromMap(e)).toList();
  }

  Future<int> insertStaffAssignment(StaffAssignment assignment) async {
    final db = await database;
    return await db.insert('staff_assignments', assignment.toMap());
  }

  Future<List<StaffAssignment>> getStaffAssignments({int? staffId}) async {
    final db = await database;
    final maps = staffId == null
        ? await db.query('staff_assignments')
        : await db.query(
            'staff_assignments',
            where: 'staff_id = ?',
            whereArgs: [staffId],
          );
    return maps.map((e) => StaffAssignment.fromMap(e)).toList();
  }

  Future<int> insertVital(StaffVital vital) async {
    final db = await database;
    final result = await db.insert('vitals', vital.toMap());
    if (await _isOnline() == false) {
      await _queueWrite(
        operationType: 'insert',
        tableName: 'vitals',
        payload: vital.toMap(),
      );
    }
    return result;
  }

  Future<List<StaffVital>> getVitals({int? patientId}) async {
    final db = await database;
    final maps = patientId == null
        ? await db.query('vitals', orderBy: 'timestamp DESC')
        : await db.query(
            'vitals',
            where: 'patient_id = ?',
            whereArgs: [patientId],
            orderBy: 'timestamp DESC',
          );
    return maps.map((e) => StaffVital.fromMap(e)).toList();
  }

  Future<int> insertHandoverNote(HandoverNote note) async {
    final db = await database;
    return await db.insert('handover_notes', note.toMap());
  }

  Future<List<HandoverNote>> getHandoverNotes({int? staffId}) async {
    final db = await database;
    final maps = staffId == null
        ? await db.query('handover_notes', orderBy: 'created_at DESC', limit: 3)
        : await db.query(
            'handover_notes',
            where: 'staff_id = ?',
            whereArgs: [staffId],
            orderBy: 'created_at DESC',
            limit: 3,
          );
    return maps.map((e) => HandoverNote.fromMap(e)).toList();
  }

  Future<int> insertInternalMessage(InternalMessage message) async {
    final db = await database;
    return await db.insert('internal_messages', message.toMap());
  }

  Future<List<InternalMessage>> getInternalMessages({
    required String channel,
  }) async {
    final db = await database;
    final maps = await db.query(
      'internal_messages',
      where: 'channel = ?',
      whereArgs: [channel],
      orderBy: 'timestamp ASC',
    );
    return maps.map((e) => InternalMessage.fromMap(e)).toList();
  }

  Future<int> insertAttendance(StaffAttendance attendance) async {
    final db = await database;
    return await db.insert('staff_attendance', attendance.toMap());
  }

  Future<List<StaffAttendance>> getAttendance({int? staffId}) async {
    final db = await database;
    final maps = staffId == null
        ? await db.query('staff_attendance', orderBy: 'clock_in DESC')
        : await db.query(
            'staff_attendance',
            where: 'staff_id = ?',
            whereArgs: [staffId],
            orderBy: 'clock_in DESC',
          );
    return maps.map((e) => StaffAttendance.fromMap(e)).toList();
  }

  Future<int> updateAttendanceClockOut(int id, String clockOut) async {
    final db = await database;
    return await db.update(
      'staff_attendance',
      {'clock_out': clockOut},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertDischargeRecord(DischargeRecord record) async {
    final db = await database;
    return await db.insert('discharge_records', record.toMap());
  }

  Future<int> insertDoctorNote(DoctorNote note) async {
    final db = await database;
    return await db.insert('doctor_notes', note.toMap());
  }

  Future<List<DoctorNote>> getDoctorNotes({int? patientId}) async {
    final db = await database;
    final maps = patientId == null
        ? await db.query('doctor_notes', orderBy: 'created_at DESC')
        : await db.query(
            'doctor_notes',
            where: 'patient_id = ?',
            whereArgs: [patientId],
            orderBy: 'created_at DESC',
          );
    return maps.map((e) => DoctorNote.fromMap(e)).toList();
  }

  Future<int> insertLeaveRequest(LeaveRequest request) async {
    final db = await database;
    return await db.insert('leave_requests', request.toMap());
  }

  Future<int> updateBedStatus({
    required int id,
    required String status,
    int? patientId,
  }) async {
    final db = await database;
    return await db.update(
      'beds',
      {
        'status': status,
        if (patientId != null) 'patient_id': patientId else 'patient_id': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertAuditEntry(AuditEntry entry) async {
    final db = await database;
    return await db.insert('audit_entries', entry.toMap());
  }

  Future<List<AuditEntry>> getAllAuditEntries() async {
    final db = await database;
    final maps = await db.query('audit_entries');
    return maps.map((e) => AuditEntry.fromMap(e)).toList();
  }

  Future<int> insertStat(Stat stat) async {
    final db = await database;
    return await db.insert('stats', stat.toMap());
  }

  Future<List<Stat>> getAllStats() async {
    final db = await database;
    final maps = await db.query('stats');
    return maps.map((e) => Stat.fromMap(e)).toList();
  }

  Future<int> insertDeptLoad(DeptLoad load) async {
    final db = await database;
    return await db.insert('dept_loads', load.toMap());
  }

  Future<List<DeptLoad>> getAllDeptLoads() async {
    final db = await database;
    final maps = await db.query('dept_loads');
    return maps.map((e) => DeptLoad.fromMap(e)).toList();
  }
}
