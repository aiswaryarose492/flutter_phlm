import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'database_helper.dart';

class DatabaseSeeder {
  /// Seed database with sample data for testing
  static Future<void> seedDatabase() async {
    final dbHelper = DatabaseHelper();

    // Create sample users
    await dbHelper.insertUser(
      User(
        username: 'admin',
        email: 'admin@hospital.com',
        password: 'admin123',
        firstName: 'Admin',
        lastName: 'User',
        isHospitalAdmin: true,
      ),
    );

    await dbHelper.insertUser(
      User(
        username: 'doctor',
        email: 'doctor@hospital.com',
        password: 'doctor123',
        firstName: 'Dr. John',
        lastName: 'Smith',
        isDoctor: true,
      ),
    );

    await dbHelper.insertUser(
      User(
        username: 'patient',
        email: 'patient@example.com',
        password: 'patient123',
        firstName: 'Jane',
        lastName: 'Doe',
        isPatient: true,
      ),
    );

    await dbHelper.insertUser(
      User(
        username: 'lab',
        email: 'lab@hospital.com',
        password: 'lab123',
        firstName: 'Lab',
        lastName: 'Technician',
        isLab: true,
      ),
    );

    await dbHelper.insertUser(
      User(
        username: 'pharmacy',
        email: 'pharmacy@hospital.com',
        password: 'pharmacy123',
        firstName: 'Pharmacist',
        lastName: 'User',
        isPharmacy: true,
      ),
    );

    await dbHelper.insertUser(
      User(
        username: 'staff',
        email: 'staff@hospital.com',
        password: 'staff123',
        firstName: 'Staff',
        lastName: 'Member',
        isStaffMember: true,
      ),
    );

    // Create sample hospital
    await dbHelper.insertHospital(
      Hospital(
        userId: 1,
        name: 'General Hospital',
        address: '123 Main St, City',
        maxLeaveDays: 12,
        extraLeaveDeduction: 100.00,
        emergencyNumber: '108',
      ),
    );

    // Create sample doctor
    await dbHelper.insertDoctor(
      Doctor(
        userId: 2,
        hospitalId: 1,
        specialty: 'Cardiology',
        department: 'Cardiology',
        experience: 10,
        available: true,
        appointmentFees: 500.00,
      ),
    );

    final doc2Id = await dbHelper.insertUser(
      User(
        username: 'doctor_neuro',
        email: 'neuro@hospital.com',
        password: 'doctor123',
        firstName: 'Dr. Priya',
        lastName: 'Menon',
        isDoctor: true,
      ),
    );
    final doc3Id = await dbHelper.insertUser(
      User(
        username: 'doctor_ortho',
        email: 'ortho@hospital.com',
        password: 'doctor123',
        firstName: 'Dr. Arjun',
        lastName: 'Nair',
        isDoctor: true,
      ),
    );
    final doc4Id = await dbHelper.insertUser(
      User(
        username: 'doctor_peds',
        email: 'peds@hospital.com',
        password: 'doctor123',
        firstName: 'Dr. Anjali',
        lastName: 'Das',
        isDoctor: true,
      ),
    );
    final doc5Id = await dbHelper.insertUser(
      User(
        username: 'doctor_derm',
        email: 'derm@hospital.com',
        password: 'doctor123',
        firstName: 'Dr. Rahul',
        lastName: 'Krishnan',
        isDoctor: true,
      ),
    );
    final doc6Id = await dbHelper.insertUser(
      User(
        username: 'doctor_card2',
        email: 'card2@hospital.com',
        password: 'doctor123',
        firstName: 'Dr. Meera',
        lastName: 'Pillai',
        isDoctor: true,
      ),
    );

    await dbHelper.insertDoctor(
      Doctor(
        userId: doc2Id,
        hospitalId: 1,
        specialty: 'Neurology',
        department: 'Neurology',
        qualification: 'DM Neurology',
        experience: 8,
        availableStartTime: '09:00',
        availableEndTime: '17:00',
        appointmentFees: 600.00,
        available: true,
      ),
    );

    await dbHelper.insertDoctor(
      Doctor(
        userId: doc3Id,
        hospitalId: 1,
        specialty: 'Orthopedics',
        department: 'Orthopedics',
        qualification: 'MS Ortho',
        experience: 12,
        availableStartTime: '10:00',
        availableEndTime: '18:00',
        appointmentFees: 550.00,
        available: true,
      ),
    );

    await dbHelper.insertDoctor(
      Doctor(
        userId: doc4Id,
        hospitalId: 1,
        specialty: 'Pediatrics',
        department: 'Pediatrics',
        qualification: 'MD Pediatrics',
        experience: 7,
        availableStartTime: '08:00',
        availableEndTime: '14:00',
        appointmentFees: 400.00,
        available: true,
      ),
    );

    await dbHelper.insertDoctor(
      Doctor(
        userId: doc5Id,
        hospitalId: 1,
        specialty: 'Dermatology',
        department: 'Dermatology',
        qualification: 'MD Dermatology',
        experience: 5,
        availableStartTime: '11:00',
        availableEndTime: '19:00',
        appointmentFees: 450.00,
        available: false,
      ),
    );

    await dbHelper.insertDoctor(
      Doctor(
        userId: doc6Id,
        hospitalId: 1,
        specialty: 'Cardiology',
        department: 'Cardiology',
        qualification: 'DM Cardiology',
        experience: 15,
        availableStartTime: '09:00',
        availableEndTime: '16:00',
        appointmentFees: 700.00,
        available: true,
      ),
    );

    await dbHelper.insertDepartment(
      Department(
        hospitalId: 1,
        name: 'Cardiology',
        description: 'Heart and cardiovascular care',
        floor: '2',
        phone: '0495-1001',
        headDoctorId: 1,
        avgWaitMinutes: 18,
      ),
    );
    await dbHelper.insertDepartment(
      Department(
        hospitalId: 1,
        name: 'Neurology',
        description: 'Brain and nervous system care',
        floor: '3',
        phone: '0495-1002',
        headDoctorId: doc2Id,
        avgWaitMinutes: 24,
      ),
    );
    await dbHelper.insertDepartment(
      Department(
        hospitalId: 1,
        name: 'Orthopedics',
        description: 'Bone, joint and injury care',
        floor: '1',
        phone: '0495-1003',
        headDoctorId: doc3Id,
        avgWaitMinutes: 15,
      ),
    );

    await dbHelper.insertMedicine(
      Medicine(
        hospitalId: 1,
        name: 'Paracetamol 500mg',
        category: 'Analgesic',
        stockQuantity: 120,
        unit: 'Tablet',
        reorderLevel: 30,
        expiryDate: '2027-12-31',
        price: 2.00,
      ),
    );
    await dbHelper.insertMedicine(
      Medicine(
        hospitalId: 1,
        name: 'Metformin 500mg',
        category: 'Diabetes',
        stockQuantity: 8,
        unit: 'Tablet',
        reorderLevel: 20,
        expiryDate: '2027-06-30',
        price: 4.00,
      ),
    );
    await dbHelper.insertMedicine(
      Medicine(
        hospitalId: 1,
        name: 'Amoxicillin 250mg',
        category: 'Antibiotic',
        stockQuantity: 5,
        unit: 'Capsule',
        reorderLevel: 15,
        expiryDate: '2026-12-31',
        price: 6.00,
      ),
    );

    await dbHelper.insertWard(
      Ward(
        hospitalId: 1,
        wardNumber: 'W1',
        wardType: 'General',
        floor: '2',
        totalBeds: 20,
        occupiedBeds: 14,
      ),
    );
    await dbHelper.insertBed(
      Bed(
        hospitalId: 1,
        wardId: 1,
        bedNumber: 'G-101',
        status: 'Occupied',
        patientId: 1,
      ),
    );
    await dbHelper.insertBed(
      Bed(hospitalId: 1, wardId: 1, bedNumber: 'G-102', status: 'Available'),
    );
    await dbHelper.insertPatientAdmission(
      PatientAdmission(
        patientId: 1,
        hospitalId: 1,
        wardId: 1,
        bedNumber: 'G-101',
        admissionReason: 'Observation after chest pain',
        admittingDoctorId: 1,
        admissionDate: DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        status: 'Admitted',
        isSerious: true,
        totalBill: 12000,
        billPaid: 6000,
      ),
    );

    await dbHelper.insertStaffTask(
      StaffTask(
        hospitalId: 1,
        assignedTo: 6,
        title: 'Prepare OPD tokens',
        description: 'Arrange morning appointment queue',
        status: 'Pending',
        priority: 'High',
        dueDate: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      ),
    );
    await dbHelper.insertStaffTask(
      StaffTask(
        hospitalId: 1,
        assignedTo: 6,
        title: 'Update discharge summary',
        description: 'Coordinate with doctor and billing desk',
        status: 'Pending',
        priority: 'Medium',
        dueDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      ),
    );

    final labOrderId = await dbHelper.insertLabOrder(
      LabOrder(
        doctorId: 1,
        patientId: 1,
        tests: const ['CBC', 'Lipid Profile'],
        priority: 'Urgent',
        status: 'Pending',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    final labResultId = await dbHelper.insertLabResult(
      LabResult(
        orderId: labOrderId,
        testName: 'CBC',
        resultValue: 'Within normal limits',
        unit: '',
        referenceRange: 'Normal',
        recordedBy: 4,
        recordedAt: DateTime.now().toIso8601String(),
      ),
    );
    await dbHelper.insertLabReport(
      LabReportRecord(
        resultId: labResultId,
        published: true,
        publishedAt: DateTime.now().toIso8601String(),
        patientVisible: true,
      ),
    );
    await dbHelper.insertLabReport(
      LabReportRecord(
        resultId: labResultId,
        published: false,
        patientVisible: false,
      ),
    );

    await dbHelper.insertRefillRequest(
      RefillRequest(
        patientId: 1,
        medicineIds: const [2, 3],
        status: 'Pending',
        requestedAt: DateTime.now().toIso8601String(),
        reason: 'Monthly refill',
      ),
    );

    await dbHelper.insertAmbulance(
      Ambulance(
        hospitalId: 1,
        vehicleNumber: 'KL-11-A-1080',
        vehicleType: 'Advanced Life Support',
        status: 'Dispatched',
        driverName: 'Raju',
        driverPhone: '9876543210',
        dispatchTime: DateTime.now().toIso8601String(),
        destination: 'Medical College Junction',
        eta: '12 mins',
      ),
    );
    await dbHelper.insertEmergencyCase(
      EmergencyCase(
        hospitalId: 1,
        patientName: 'Emergency patient',
        symptoms: 'Breathing difficulty',
        severity: 'High',
        assignedTo: 6,
        status: 'Open',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    // Create sample patient
    await dbHelper.insertPatient(
      Patient(
        userId: 3,
        hospitalId: 1,
        phone: '555-1234',
        gender: 'Male',
        address: '456 Oak Ave',
        name: 'Jane Doe',
        photoPath: 'assets/avatar_patient.png',
      ),
    );

    await dbHelper.insertFamilyMember(
      FamilyMember(patientId: 1, name: 'Jane Doe', relation: 'Self', age: 34),
    );

    await dbHelper.insertFamilyMember(
      FamilyMember(patientId: 1, name: 'John Doe', relation: 'Spouse', age: 36),
    );

    await dbHelper.insertFamilyMember(
      FamilyMember(patientId: 1, name: 'Ava Doe', relation: 'Child', age: 8),
    );

    await dbHelper.insertAppointment(
      Appointment(
        id: 1,
        doctorId: 1,
        patientId: 1,
        date: DateTime.now().add(const Duration(days: 1)).toString(),
        time: '10:00',
        symptoms: 'Routine follow-up',
        status: 'Completed',
      ),
    );

    await dbHelper.insertPrescription(
      Prescription(
        appointmentId: 1,
        patientId: 1,
        medicines: jsonEncode(const [
          {
            'name': 'Warfarin',
            'dosage': '5mg',
            'frequency': 'OD',
            'duration': '30 days',
            'instructions': 'Take with water',
          },
          {
            'name': 'Metformin',
            'dosage': '500mg',
            'frequency': 'BD',
            'duration': '30 days',
            'instructions': 'Take after food',
          },
        ]),
        notes: 'Sample prescription for medication reminders.',
        isDispensed: false,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertPatientVital(
      PatientVital(
        patientId: 1,
        bpSystolic: 120,
        bpDiastolic: 80,
        spo2: 98,
        weight: 68,
        recordedAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertLabOrder(
      LabOrder(
        doctorId: 1,
        patientId: 1,
        tests: const ['CBC', 'Blood Sugar'],
        priority: 'Routine',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertStaffAssignment(
      StaffAssignment(
        staffId: 6,
        patientId: 1,
        bedNumber: 'ICU-1',
        shift: 'Day',
      ),
    );

    await dbHelper.insertVital(
      StaffVital(
        patientId: 1,
        recordedBy: 6,
        timestamp: DateTime.now().toIso8601String(),
        bpSys: 120,
        bpDia: 80,
        spo2: 98,
        temp: 98.6,
        pulse: 76,
        weight: 68,
      ),
    );

    await dbHelper.insertHandoverNote(
      HandoverNote(
        staffId: 6,
        shift: 'Day',
        summary: 'Patient in ICU-1 stable. Monitor vitals every 4 hours.',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertInternalMessage(
      InternalMessage(
        channel: 'ICU',
        senderId: 6,
        text: 'ICU handover completed.',
        timestamp: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertAttendance(
      StaffAttendance(staffId: 6, clockIn: DateTime.now().toIso8601String()),
    );

    await dbHelper.insertDoctorNote(
      DoctorNote(
        patientId: 1,
        doctorId: 1,
        note: 'Continue observation and review vitals after lunch.',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertBed(
      Bed(
        hospitalId: 1,
        wardId: 1,
        bedNumber: 'ICU-1',
        status: 'Occupied',
        patientId: 1,
      ),
    );

    await dbHelper.insertDepartment(
      Department(
        hospitalId: 1,
        name: 'Cardiology',
        description: 'Heart and vascular care',
        floor: '2',
        phone: '555-2001',
      ),
    );

    await dbHelper.insertDepartment(
      Department(
        hospitalId: 1,
        name: 'Pharmacy',
        description: 'Medicine dispensing',
        floor: '1',
        phone: '555-2002',
      ),
    );

    await dbHelper.insertBill(
      Bill(
        patientId: 1,
        hospitalId: 1,
        billNumber: 'BL-1001',
        amount: 2500,
        paidAmount: 1000,
        status: 'Partially Paid',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertQueueEntry(
      QueueEntry(
        hospitalId: 1,
        departmentId: 1,
        patientId: 1,
        doctorId: 1,
        tokenNumber: 1,
        status: 'Waiting',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertStaffTask(
      StaffTask(
        hospitalId: 1,
        assignedTo: 6,
        title: 'Prepare OPD queue',
        description: 'Update waiting room status',
        status: 'Pending',
        priority: 'High',
      ),
    );

    await dbHelper.insertBed(
      Bed(hospitalId: 1, wardId: 1, bedNumber: 'ICU-1', status: 'Available'),
    );

    await dbHelper.insertAuditEntry(
      AuditEntry(
        userId: 1,
        action: 'LOGIN',
        entityType: 'User',
        entityId: 1,
        details: 'Sample audit entry',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertStat(
      Stat(
        hospitalId: 1,
        metricKey: 'daily_appointments',
        metricValue: 42,
        recordedAt: DateTime.now().toIso8601String(),
      ),
    );

    await dbHelper.insertMedicine(
      Medicine(
        hospitalId: 1,
        name: 'Paracetamol',
        brand: 'Cipla',
        category: 'Tablet',
        stockQuantity: 80,
        unit: 'Strip',
        reorderLevel: 20,
        expiryDate: DateTime.now()
            .add(const Duration(days: 180))
            .toIso8601String(),
        price: 25,
        manufacturer: 'Cipla',
      ),
    );
    await dbHelper.insertMedicine(
      Medicine(
        hospitalId: 1,
        name: 'Amoxicillin',
        brand: 'Sun Pharma',
        category: 'Syrup',
        stockQuantity: 3,
        unit: 'Bottle',
        reorderLevel: 10,
        expiryDate: DateTime.now()
            .add(const Duration(days: 20))
            .toIso8601String(),
        price: 120,
        manufacturer: 'Sun Pharma',
      ),
    );
    await dbHelper.insertHomeDeliveryOrder(
      HomeDeliveryOrder(
        patientId: 1,
        prescriptionId: 1,
        address: '12 Lake Road',
        status: 'Pending',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await dbHelper.insertRefillRequest(
      RefillRequest(
        patientId: 1,
        medicineIds: const [1, 2],
        status: 'Pending',
        requestedAt: DateTime.now().toIso8601String(),
      ),
    );

    final pendingLabOrderId = await dbHelper.insertLabOrder(
      LabOrder(
        doctorId: 1,
        patientId: 1,
        tests: const ['CBC', 'Blood Sugar'],
        priority: 'Stat',
        status: 'Pending',
        createdAt: DateTime.now().toIso8601String(),
        instructions: 'Fasting sample requested',
      ),
    );
    final processingLabOrderId = await dbHelper.insertLabOrder(
      LabOrder(
        id: pendingLabOrderId + 1,
        doctorId: 1,
        patientId: 1,
        tests: const ['Lipid Profile'],
        priority: 'Urgent',
        status: 'Processing',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        currentStep: 1,
        lastStepAt: DateTime.now().toIso8601String(),
      ),
    );
    final resultId = await dbHelper.insertLabResult(
      LabResult(
        orderId: processingLabOrderId,
        testName: 'Lipid Profile',
        resultValue: '180',
        unit: 'mg/dL',
        referenceRange: '0-150',
        flagged: true,
        recordedBy: 4,
        recordedAt: DateTime.now().toIso8601String(),
      ),
    );
    await dbHelper.insertLabReport(
      LabReportRecord(
        resultId: resultId,
        published: true,
        publishedAt: DateTime.now().toIso8601String(),
        patientVisible: true,
      ),
    );
  }

  static Future<void> ensureSampleData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    int? doc2Id;
    int? doc3Id;
    int? doc4Id;
    int? doc5Id;
    int? doc6Id;

    if (!await _exists(db, 'users', 'username', 'doctor_neuro')) {
      doc2Id = await dbHelper.insertUser(
        User(
          username: 'doctor_neuro',
          email: 'neuro@hospital.com',
          password: 'doctor123',
          firstName: 'Dr. Priya',
          lastName: 'Menon',
          isDoctor: true,
        ),
      );
      await dbHelper.insertDoctor(
        Doctor(
          userId: doc2Id,
          hospitalId: 1,
          specialty: 'Neurology',
          department: 'Neurology',
          qualification: 'DM Neurology',
          experience: 8,
          availableStartTime: '09:00',
          availableEndTime: '17:00',
          appointmentFees: 600.00,
          available: true,
        ),
      );
    }

    if (!await _exists(db, 'users', 'username', 'doctor_ortho')) {
      doc3Id = await dbHelper.insertUser(
        User(
          username: 'doctor_ortho',
          email: 'ortho@hospital.com',
          password: 'doctor123',
          firstName: 'Dr. Arjun',
          lastName: 'Nair',
          isDoctor: true,
        ),
      );
      await dbHelper.insertDoctor(
        Doctor(
          userId: doc3Id,
          hospitalId: 1,
          specialty: 'Orthopedics',
          department: 'Orthopedics',
          qualification: 'MS Ortho',
          experience: 12,
          availableStartTime: '10:00',
          availableEndTime: '18:00',
          appointmentFees: 550.00,
          available: true,
        ),
      );
    }

    if (!await _exists(db, 'users', 'username', 'doctor_peds')) {
      doc4Id = await dbHelper.insertUser(
        User(
          username: 'doctor_peds',
          email: 'peds@hospital.com',
          password: 'doctor123',
          firstName: 'Dr. Anjali',
          lastName: 'Das',
          isDoctor: true,
        ),
      );
      await dbHelper.insertDoctor(
        Doctor(
          userId: doc4Id,
          hospitalId: 1,
          specialty: 'Pediatrics',
          department: 'Pediatrics',
          qualification: 'MD Pediatrics',
          experience: 7,
          availableStartTime: '08:00',
          availableEndTime: '14:00',
          appointmentFees: 400.00,
          available: true,
        ),
      );
    }

    if (!await _exists(db, 'users', 'username', 'doctor_derm')) {
      doc5Id = await dbHelper.insertUser(
        User(
          username: 'doctor_derm',
          email: 'derm@hospital.com',
          password: 'doctor123',
          firstName: 'Dr. Rahul',
          lastName: 'Krishnan',
          isDoctor: true,
        ),
      );
      await dbHelper.insertDoctor(
        Doctor(
          userId: doc5Id,
          hospitalId: 1,
          specialty: 'Dermatology',
          department: 'Dermatology',
          qualification: 'MD Dermatology',
          experience: 5,
          availableStartTime: '11:00',
          availableEndTime: '19:00',
          appointmentFees: 450.00,
          available: false,
        ),
      );
    }

    if (!await _exists(db, 'users', 'username', 'doctor_card2')) {
      doc6Id = await dbHelper.insertUser(
        User(
          username: 'doctor_card2',
          email: 'card2@hospital.com',
          password: 'doctor123',
          firstName: 'Dr. Meera',
          lastName: 'Pillai',
          isDoctor: true,
        ),
      );
      await dbHelper.insertDoctor(
        Doctor(
          userId: doc6Id,
          hospitalId: 1,
          specialty: 'Cardiology',
          department: 'Cardiology',
          qualification: 'DM Cardiology',
          experience: 15,
          availableStartTime: '09:00',
          availableEndTime: '16:00',
          appointmentFees: 700.00,
          available: true,
        ),
      );
    }

    final departments = const {
      'Cardiology': ['2', '0495-1001'],
      'Neurology': ['3', '0495-1002'],
      'Orthopedics': ['1', '0495-1003'],
      'Pediatrics': ['2', '0495-1004'],
      'Dermatology': ['3', '0495-1005'],
    };

    for (final entry in departments.entries) {
      if (!await _exists(db, 'departments', 'name', entry.key)) {
        await dbHelper.insertDepartment(
          Department(
            hospitalId: 1,
            name: entry.key,
            description: '${entry.key} department',
            floor: entry.value[0],
            phone: entry.value[1],
            headDoctorId: doc2Id ?? doc3Id ?? doc4Id ?? doc5Id ?? doc6Id,
            avgWaitMinutes: 20,
          ),
        );
      }
    }

    if (!await _exists(db, 'medicines', 'name', 'Metformin 500mg')) {
      await dbHelper.insertMedicine(
        Medicine(
          hospitalId: 1,
          name: 'Metformin 500mg',
          category: 'Diabetes',
          stockQuantity: 8,
          unit: 'Tablet',
          reorderLevel: 20,
          expiryDate: '2027-06-30',
          price: 4.00,
        ),
      );
    }

    if (!await _exists(db, 'medicines', 'name', 'Amoxicillin 250mg')) {
      await dbHelper.insertMedicine(
        Medicine(
          hospitalId: 1,
          name: 'Amoxicillin 250mg',
          category: 'Antibiotic',
          stockQuantity: 5,
          unit: 'Capsule',
          reorderLevel: 15,
          expiryDate: '2026-12-31',
          price: 6.00,
        ),
      );
    }

    if (!await _exists(db, 'staff_tasks', 'title', 'Prepare OPD tokens')) {
      await dbHelper.insertStaffTask(
        StaffTask(
          hospitalId: 1,
          assignedTo: 6,
          title: 'Prepare OPD tokens',
          description: 'Arrange morning appointment queue',
          status: 'Pending',
          priority: 'High',
          dueDate: DateTime.now()
              .add(const Duration(hours: 2))
              .toIso8601String(),
        ),
      );
    }

    if (!await _exists(db, 'refill_requests', 'reason', 'Monthly refill')) {
      await dbHelper.insertRefillRequest(
        RefillRequest(
          patientId: 1,
          medicineIds: const [2, 3],
          status: 'Pending',
          requestedAt: DateTime.now().toIso8601String(),
          reason: 'Monthly refill',
        ),
      );
    }

    if (!await _exists(
      db,
      'emergency_cases',
      'symptoms',
      'Breathing difficulty',
    )) {
      await dbHelper.insertEmergencyCase(
        EmergencyCase(
          hospitalId: 1,
          patientName: 'Emergency patient',
          symptoms: 'Breathing difficulty',
          severity: 'High',
          assignedTo: 6,
          status: 'Open',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  static Future<bool> _exists(
    Database db,
    String table,
    String column,
    String value,
  ) async {
    final rows = await db.query(
      table,
      columns: const ['id'],
      where: '$column = ?',
      whereArgs: [value],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
