import 'dart:convert';

// StaffAssignment model
class StaffAssignment {
  final int? id;
  final int staffId;
  final int patientId;
  final String? bedNumber;
  final String? shift;

  StaffAssignment({
    this.id,
    required this.staffId,
    required this.patientId,
    this.bedNumber,
    this.shift,
  });

  factory StaffAssignment.fromMap(Map<String, dynamic> json) => StaffAssignment(
    id: json['id'] as int?,
    staffId: json['staff_id'] as int? ?? 0,
    patientId: json['patient_id'] as int? ?? 0,
    bedNumber: json['bed_number'] as String?,
    shift: json['shift'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'staff_id': staffId,
    'patient_id': patientId,
    'bed_number': bedNumber,
    'shift': shift,
  };
}

// StaffVital model
class StaffVital {
  final int? id;
  final int patientId;
  final int recordedBy;
  final String timestamp;
  final int bpSys;
  final int bpDia;
  final int spo2;
  final double temp;
  final int pulse;
  final double weight;

  StaffVital({
    this.id,
    required this.patientId,
    required this.recordedBy,
    required this.timestamp,
    required this.bpSys,
    required this.bpDia,
    required this.spo2,
    required this.temp,
    required this.pulse,
    required this.weight,
  });

  factory StaffVital.fromMap(Map<String, dynamic> json) => StaffVital(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int? ?? 0,
    recordedBy: json['recorded_by'] as int? ?? 0,
    timestamp: json['timestamp'] as String? ?? '',
    bpSys: json['bp_sys'] as int? ?? 0,
    bpDia: json['bp_dia'] as int? ?? 0,
    spo2: json['spo2'] as int? ?? 0,
    temp: (json['temp'] as num?)?.toDouble() ?? 0.0,
    pulse: json['pulse'] as int? ?? 0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'recorded_by': recordedBy,
    'timestamp': timestamp,
    'bp_sys': bpSys,
    'bp_dia': bpDia,
    'spo2': spo2,
    'temp': temp,
    'pulse': pulse,
    'weight': weight,
  };
}

// HandoverNote model
class HandoverNote {
  final int? id;
  final int staffId;
  final String? shift;
  final String summary;
  final String createdAt;
  final bool shiftComplete;

  HandoverNote({
    this.id,
    required this.staffId,
    this.shift,
    required this.summary,
    required this.createdAt,
    this.shiftComplete = false,
  });

  factory HandoverNote.fromMap(Map<String, dynamic> json) => HandoverNote(
    id: json['id'] as int?,
    staffId: json['staff_id'] as int? ?? 0,
    shift: json['shift'] as String?,
    summary: json['summary'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
    shiftComplete: json['shift_complete'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'staff_id': staffId,
    'shift': shift,
    'summary': summary,
    'created_at': createdAt,
    'shift_complete': shiftComplete ? 1 : 0,
  };
}

// InternalMessage model
class InternalMessage {
  final int? id;
  final String channel;
  final int senderId;
  final String text;
  final String timestamp;
  final bool isRead;

  InternalMessage({
    this.id,
    required this.channel,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory InternalMessage.fromMap(Map<String, dynamic> json) => InternalMessage(
    id: json['id'] as int?,
    channel: json['channel'] as String? ?? '',
    senderId: json['sender_id'] as int? ?? 0,
    text: json['text'] as String? ?? '',
    timestamp: json['timestamp'] as String? ?? '',
    isRead: json['is_read'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'channel': channel,
    'sender_id': senderId,
    'text': text,
    'timestamp': timestamp,
    'is_read': isRead ? 1 : 0,
  };
}

// StaffAttendance model
class StaffAttendance {
  final int? id;
  final int staffId;
  final String clockIn;
  final String? clockOut;

  StaffAttendance({
    this.id,
    required this.staffId,
    required this.clockIn,
    this.clockOut,
  });

  factory StaffAttendance.fromMap(Map<String, dynamic> json) => StaffAttendance(
    id: json['id'] as int?,
    staffId: json['staff_id'] as int? ?? 0,
    clockIn: json['clock_in'] as String? ?? '',
    clockOut: json['clock_out'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'staff_id': staffId,
    'clock_in': clockIn,
    'clock_out': clockOut,
  };
}

// DischargeRecord model
class DischargeRecord {
  final int? id;
  final int patientId;
  final int bedId;
  final String bedNumber;
  final String dischargedAt;
  final String? notes;

  DischargeRecord({
    this.id,
    required this.patientId,
    required this.bedId,
    required this.bedNumber,
    required this.dischargedAt,
    this.notes,
  });

  factory DischargeRecord.fromMap(Map<String, dynamic> json) => DischargeRecord(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int? ?? 0,
    bedId: json['bed_id'] as int? ?? 0,
    bedNumber: json['bed_number'] as String? ?? '',
    dischargedAt: json['discharged_at'] as String? ?? '',
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'bed_id': bedId,
    'bed_number': bedNumber,
    'discharged_at': dischargedAt,
    'notes': notes,
  };
}

// DoctorNote model
class DoctorNote {
  final int? id;
  final int patientId;
  final int doctorId;
  final String note;
  final String createdAt;

  DoctorNote({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.note,
    required this.createdAt,
  });

  factory DoctorNote.fromMap(Map<String, dynamic> json) => DoctorNote(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int? ?? 0,
    doctorId: json['doctor_id'] as int? ?? 0,
    note: json['note'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'note': note,
    'created_at': createdAt,
  };
}

// LeaveRequest model
class LeaveRequest {
  final int? id;
  final int staffId;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;
  final String appliedAt;

  LeaveRequest({
    this.id,
    required this.staffId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'Pending',
    required this.appliedAt,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> json) => LeaveRequest(
    id: json['id'] as int?,
    staffId: json['staff_id'] as int? ?? 0,
    leaveType: json['leave_type'] as String? ?? 'Casual',
    startDate: json['start_date'] as String? ?? '',
    endDate: json['end_date'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    status: json['status'] as String? ?? 'Pending',
    appliedAt: json['applied_at'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'staff_id': staffId,
    'leave_type': leaveType,
    'start_date': startDate,
    'end_date': endDate,
    'reason': reason,
    'status': status,
    'applied_at': appliedAt,
  };
}

// LabOrder model
class LabOrder {
  final int? id;
  final int? doctorId;
  final int? patientId;
  final List<String> tests;
  final String priority;
  final String status;
  final String createdAt;
  final String? instructions;
  final int currentStep;
  final String? lastStepAt;

  LabOrder({
    this.id,
    this.doctorId,
    this.patientId,
    required this.tests,
    this.priority = 'Routine',
    this.status = 'Pending',
    this.createdAt = '',
    this.instructions,
    this.currentStep = 0,
    this.lastStepAt,
  });

  factory LabOrder.fromMap(Map<String, dynamic> json) => LabOrder(
    id: json['id'] as int?,
    doctorId: json['doctor_id'] as int?,
    patientId: json['patient_id'] as int?,
    tests: _decodeTests(json['tests_json'] as String?),
    priority: json['priority'] as String? ?? 'Routine',
    status: json['status'] as String? ?? 'Pending',
    createdAt: json['created_at'] as String? ?? '',
    instructions: json['instructions'] as String?,
    currentStep: json['current_step'] as int? ?? 0,
    lastStepAt: json['last_step_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctor_id': doctorId,
    'patient_id': patientId,
    'tests_json': jsonEncode(tests),
    'priority': priority,
    'status': status,
    'created_at': createdAt,
    'instructions': instructions,
    'current_step': currentStep,
    'last_step_at': lastStepAt,
  };

  LabOrder copyWith({
    int? id,
    int? doctorId,
    int? patientId,
    List<String>? tests,
    String? priority,
    String? status,
    String? createdAt,
    String? instructions,
    int? currentStep,
    String? lastStepAt,
  }) {
    return LabOrder(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      tests: tests ?? this.tests,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      instructions: instructions ?? this.instructions,
      currentStep: currentStep ?? this.currentStep,
      lastStepAt: lastStepAt ?? this.lastStepAt,
    );
  }

  static List<String> _decodeTests(String? encoded) {
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
}

class LabResult {
  final int? id;
  final int? orderId;
  final String testName;
  final String resultValue;
  final String unit;
  final String referenceRange;
  final bool flagged;
  final int? recordedBy;
  final String recordedAt;

  LabResult({
    this.id,
    this.orderId,
    required this.testName,
    required this.resultValue,
    required this.unit,
    required this.referenceRange,
    this.flagged = false,
    this.recordedBy,
    this.recordedAt = '',
  });

  factory LabResult.fromMap(Map<String, dynamic> json) => LabResult(
    id: json['id'] as int?,
    orderId: json['order_id'] as int?,
    testName: json['test_name'] as String? ?? '',
    resultValue: json['result_value'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    referenceRange: json['reference_range'] as String? ?? '',
    flagged: json['flagged'] == 1,
    recordedBy: json['recorded_by'] as int?,
    recordedAt: json['recorded_at'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'order_id': orderId,
    'test_name': testName,
    'result_value': resultValue,
    'unit': unit,
    'reference_range': referenceRange,
    'flagged': flagged ? 1 : 0,
    'recorded_by': recordedBy,
    'recorded_at': recordedAt,
  };
}

class LabReportRecord {
  final int? id;
  final int? resultId;
  final bool published;
  final String? publishedAt;
  final bool patientVisible;

  LabReportRecord({
    this.id,
    this.resultId,
    this.published = false,
    this.publishedAt,
    this.patientVisible = false,
  });
  factory LabReportRecord.fromMap(Map<String, dynamic> json) => LabReportRecord(
    id: json['id'] as int?,
    resultId: json['result_id'] as int?,
    published: json['published'] == 1,
    publishedAt: json['published_at'] as String?,
    patientVisible: json['patient_visible'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'result_id': resultId,
    'published': published ? 1 : 0,
    'published_at': publishedAt,
    'patient_visible': patientVisible ? 1 : 0,
  };
}

// AdminStaff model
class AdminStaff {
  final int? id;
  final int? userId;
  final int? hospitalId;
  final String? name;
  final String role;
  final String? department;
  final String? shiftPattern;
  final String? phone;
  final String? joiningDate;
  final String status;

  AdminStaff({
    this.id,
    this.userId,
    this.hospitalId,
    this.name,
    this.role = 'Nurse',
    this.department,
    this.shiftPattern,
    this.phone,
    this.joiningDate,
    this.status = 'Active',
  });

  factory AdminStaff.fromMap(Map<String, dynamic> json) => AdminStaff(
    id: json['id'] as int?,
    userId: json['user_id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    name: json['name'] as String?,
    role: json['role'] as String? ?? 'Nurse',
    department: json['department'] as String?,
    shiftPattern: json['shift_pattern'] as String?,
    phone: json['phone'] as String?,
    joiningDate: json['joining_date'] as String?,
    status: json['status'] as String? ?? 'Active',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'hospital_id': hospitalId,
    'name': name,
    'role': role,
    'department': department,
    'shift_pattern': shiftPattern,
    'phone': phone,
    'joining_date': joiningDate,
    'status': status,
  };
}

// PatientVital model
class PatientVital {
  final int? id;
  final int patientId;
  final int bpSystolic;
  final int bpDiastolic;
  final int spo2;
  final double weight;
  final String? recordedAt;

  PatientVital({
    this.id,
    required this.patientId,
    required this.bpSystolic,
    required this.bpDiastolic,
    required this.spo2,
    required this.weight,
    this.recordedAt,
  });

  factory PatientVital.fromMap(Map<String, dynamic> json) => PatientVital(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int? ?? 0,
    bpSystolic: json['bp_systolic'] as int? ?? 0,
    bpDiastolic: json['bp_diastolic'] as int? ?? 0,
    spo2: json['spo2'] as int? ?? 0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    recordedAt: json['recorded_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'bp_systolic': bpSystolic,
    'bp_diastolic': bpDiastolic,
    'spo2': spo2,
    'weight': weight,
    'recorded_at': recordedAt,
  };
}

// FamilyMember model
class FamilyMember {
  final int? id;
  final int patientId;
  final String name;
  final String relation;
  final int age;

  FamilyMember({
    this.id,
    required this.patientId,
    required this.name,
    required this.relation,
    required this.age,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    relation: json['relation'] as String? ?? '',
    age: json['age'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'name': name,
    'relation': relation,
    'age': age,
  };
}

class PendingSync {
  final int? id;
  final String operationType;
  final String tableName;
  final Map<String, dynamic> payload;
  final String createdAt;
  final String? syncedAt;

  PendingSync({
    this.id,
    required this.operationType,
    required this.tableName,
    required this.payload,
    this.createdAt = '',
    this.syncedAt,
  });

  factory PendingSync.fromMap(Map<String, dynamic> json) => PendingSync(
    id: json['id'] as int?,
    operationType: json['operation_type'] as String? ?? '',
    tableName: json['table_name'] as String? ?? '',
    payload: _decodeMap(json['payload_json'] as String?),
    createdAt: json['created_at'] as String? ?? '',
    syncedAt: json['synced_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'operation_type': operationType,
    'table_name': tableName,
    'payload_json': jsonEncode(payload),
    'created_at': createdAt,
    'synced_at': syncedAt,
  };
}

class HealthReward {
  final int? id;
  final int? patientId;
  final int points;
  final String reason;
  final String earnedAt;

  HealthReward({
    this.id,
    this.patientId,
    required this.points,
    required this.reason,
    this.earnedAt = '',
  });

  factory HealthReward.fromMap(Map<String, dynamic> json) => HealthReward(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int?,
    points: json['points'] as int? ?? 0,
    reason: json['reason'] as String? ?? '',
    earnedAt: json['earned_at'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'points': points,
    'reason': reason,
    'earned_at': earnedAt,
  };
}

class DispensingLog {
  final int? id;
  final int? prescriptionId;
  final int? pharmacistId;
  final int? patientId;
  final List<String> medicines;
  final String dispensedAt;
  final double totalAmount;

  DispensingLog({
    this.id,
    this.prescriptionId,
    this.pharmacistId,
    this.patientId,
    required this.medicines,
    this.dispensedAt = '',
    this.totalAmount = 0.00,
  });

  factory DispensingLog.fromMap(Map<String, dynamic> json) => DispensingLog(
    id: json['id'] as int?,
    prescriptionId: json['prescription_id'] as int?,
    pharmacistId: json['pharmacist_id'] as int?,
    patientId: json['patient_id'] as int?,
    medicines: _decodeStrings(json['medicines_json'] as String?),
    dispensedAt: json['dispensed_at'] as String? ?? '',
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.00,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'prescription_id': prescriptionId,
    'pharmacist_id': pharmacistId,
    'patient_id': patientId,
    'medicines_json': jsonEncode(medicines),
    'dispensed_at': dispensedAt,
    'total_amount': totalAmount,
  };
}

class HomeDeliveryOrder {
  final int? id;
  final int? patientId;
  final int? prescriptionId;
  final String address;
  final String status;
  final String createdAt;
  final String? dispatchedAt;

  HomeDeliveryOrder({
    this.id,
    this.patientId,
    this.prescriptionId,
    required this.address,
    this.status = 'Pending',
    this.createdAt = '',
    this.dispatchedAt,
  });

  factory HomeDeliveryOrder.fromMap(Map<String, dynamic> json) =>
      HomeDeliveryOrder(
        id: json['id'] as int?,
        patientId: json['patient_id'] as int?,
        prescriptionId: json['prescription_id'] as int?,
        address: json['address'] as String? ?? '',
        status: json['status'] as String? ?? 'Pending',
        createdAt: json['created_at'] as String? ?? '',
        dispatchedAt: json['dispatched_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'prescription_id': prescriptionId,
    'address': address,
    'status': status,
    'created_at': createdAt,
    'dispatched_at': dispatchedAt,
  };

  HomeDeliveryOrder copyWith({
    int? id,
    int? patientId,
    int? prescriptionId,
    String? address,
    String? status,
    String? createdAt,
    String? dispatchedAt,
  }) {
    return HomeDeliveryOrder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
    );
  }
}

class RefillRequest {
  final int? id;
  final int? patientId;
  final List<int> medicineIds;
  final String status;
  final String requestedAt;
  final String? processedAt;
  final String? reason;

  RefillRequest({
    this.id,
    this.patientId,
    required this.medicineIds,
    this.status = 'Pending',
    this.requestedAt = '',
    this.processedAt,
    this.reason,
  });

  factory RefillRequest.fromMap(Map<String, dynamic> json) => RefillRequest(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int?,
    medicineIds: _decodeInts(json['medicine_ids_json'] as String?),
    status: json['status'] as String? ?? 'Pending',
    requestedAt: json['requested_at'] as String? ?? '',
    processedAt: json['processed_at'] as String?,
    reason: json['reason'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'medicine_ids_json': jsonEncode(medicineIds),
    'status': status,
    'requested_at': requestedAt,
    'processed_at': processedAt,
    'reason': reason,
  };

  RefillRequest copyWith({
    int? id,
    int? patientId,
    List<int>? medicineIds,
    String? status,
    String? requestedAt,
    String? processedAt,
    String? reason,
  }) {
    return RefillRequest(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      medicineIds: medicineIds ?? this.medicineIds,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      reason: reason ?? this.reason,
    );
  }
}

// Prescription model
class Prescription {
  final int? id;
  final int? appointmentId;
  final int? patientId;
  final String? medicines;
  final String? notes;
  final bool isDispensed;
  final String? createdAt;

  Prescription({
    this.id,
    this.appointmentId,
    this.patientId,
    this.medicines,
    this.notes,
    this.isDispensed = false,
    this.createdAt,
  });

  factory Prescription.fromMap(Map<String, dynamic> json) => Prescription(
    id: json['id'] as int?,
    appointmentId: json['appointment_id'] as int?,
    patientId: json['patient_id'] as int? ?? json['linked_patient_id'] as int?,
    medicines: json['medicines'] as String?,
    notes: json['notes'] as String?,
    isDispensed: json['is_dispensed'] == 1,
    createdAt: json['created_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'appointment_id': appointmentId,
    'patient_id': patientId,
    'medicines': medicines,
    'notes': notes,
    'is_dispensed': isDispensed ? 1 : 0,
    'created_at': createdAt,
  };

  Prescription copyWith({
    int? id,
    int? appointmentId,
    int? patientId,
    String? medicines,
    String? notes,
    bool? isDispensed,
    String? createdAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      medicines: medicines ?? this.medicines,
      notes: notes ?? this.notes,
      isDispensed: isDispensed ?? this.isDispensed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Reminder model
class Reminder {
  final int? id;
  final int? patientId;
  final String? type;
  final String? message;
  final String? time;
  final String? lastTaken;
  final bool isActive;

  Reminder({
    this.id,
    this.patientId,
    this.type,
    this.message,
    this.time,
    this.lastTaken,
    this.isActive = true,
  });

  factory Reminder.fromMap(Map<String, dynamic> json) => Reminder(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int?,
    type: json['type'] as String?,
    message: json['message'] as String?,
    time: json['time'] as String?,
    lastTaken: json['last_taken'] as String?,
    isActive: json['is_active'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'type': type,
    'message': message,
    'time': time,
    'last_taken': lastTaken,
    'is_active': isActive ? 1 : 0,
  };
}

// LabReport model
class LabReport {
  final int? id;
  final int? patientId;
  final int? doctorId;
  final int? hospitalId;
  final String? title;
  final String? testType;
  final String? filePath;
  final String? patientUpload;
  final String? result;
  final String? uploadedAt;

  LabReport({
    this.id,
    this.patientId,
    this.doctorId,
    this.hospitalId,
    this.title,
    this.testType,
    this.filePath,
    this.patientUpload,
    this.result,
    this.uploadedAt,
  });

  factory LabReport.fromMap(Map<String, dynamic> json) => LabReport(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int?,
    doctorId: json['doctor_id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    title: json['title'] as String?,
    testType: json['test_type'] as String?,
    filePath: json['file_path'] as String?,
    patientUpload: json['patient_upload'] as String?,
    result: json['result'] as String?,
    uploadedAt: json['uploaded_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'hospital_id': hospitalId,
    'title': title,
    'test_type': testType,
    'file_path': filePath,
    'patient_upload': patientUpload,
    'result': result,
    'uploaded_at': uploadedAt,
  };
}

// Medicine model
class Medicine {
  final int? id;
  final int? hospitalId;
  final String? name;
  final String? genericName;
  final String? medicineType;
  final String? manufacturer;
  final String? brand;
  final String? category;
  final int stockQuantity;
  final String? unit;
  final int reorderLevel;
  final String? expiryDate;
  final double price;
  final bool prescriptionOnly;
  final double unitPrice;
  final bool isAvailable;
  final bool isExternal;

  Medicine({
    this.id,
    this.hospitalId,
    this.name,
    this.genericName,
    this.medicineType,
    this.manufacturer,
    this.brand,
    this.category,
    this.stockQuantity = 0,
    this.unit,
    this.reorderLevel = 10,
    this.expiryDate,
    this.price = 0.00,
    this.prescriptionOnly = true,
    this.unitPrice = 0.00,
    this.isAvailable = true,
    this.isExternal = false,
  });

  factory Medicine.fromMap(Map<String, dynamic> json) => Medicine(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    name: json['name'] as String?,
    genericName: json['generic_name'] as String?,
    medicineType: json['medicine_type'] as String?,
    manufacturer: json['manufacturer'] as String?,
    brand: json['brand'] as String?,
    category: json['category'] as String?,
    stockQuantity:
        (json['stock_qty'] as int? ?? json['stock_quantity'] as int?) ?? 0,
    unit: json['unit'] as String?,
    reorderLevel: json['reorder_level'] as int? ?? 10,
    expiryDate: json['expiry_date'] as String?,
    price: (json['price'] as num?)?.toDouble() ?? 0.00,
    prescriptionOnly: json['prescription_only'] != 0,
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.00,
    isAvailable: json['is_available'] == 1,
    isExternal: json['is_external'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'name': name,
    'generic_name': genericName,
    'medicine_type': medicineType,
    'manufacturer': manufacturer,
    'brand': brand,
    'category': category,
    'stock_quantity': stockQuantity,
    'stock_qty': stockQuantity,
    'unit': unit,
    'reorder_level': reorderLevel,
    'expiry_date': expiryDate,
    'price': price,
    'prescription_only': prescriptionOnly ? 1 : 0,
    'unit_price': unitPrice,
    'is_available': isAvailable ? 1 : 0,
    'is_external': isExternal ? 1 : 0,
  };

  Medicine copyWith({
    int? id,
    int? hospitalId,
    String? name,
    String? genericName,
    String? medicineType,
    String? manufacturer,
    String? brand,
    String? category,
    int? stockQuantity,
    String? unit,
    int? reorderLevel,
    String? expiryDate,
    double? price,
    bool? prescriptionOnly,
    double? unitPrice,
    bool? isAvailable,
    bool? isExternal,
  }) {
    return Medicine(
      id: id ?? this.id,
      hospitalId: hospitalId ?? this.hospitalId,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      medicineType: medicineType ?? this.medicineType,
      manufacturer: manufacturer ?? this.manufacturer,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      expiryDate: expiryDate ?? this.expiryDate,
      price: price ?? this.price,
      prescriptionOnly: prescriptionOnly ?? this.prescriptionOnly,
      unitPrice: unitPrice ?? this.unitPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      isExternal: isExternal ?? this.isExternal,
    );
  }
}

// Notification model
class Notification {
  final int? id;
  final int? recipientId;
  final String? message;
  final String? type;
  final bool isRead;
  final String? createdAt;

  Notification({
    this.id,
    this.recipientId,
    this.message,
    this.type = 'General',
    this.isRead = false,
    this.createdAt,
  });

  factory Notification.fromMap(Map<String, dynamic> json) => Notification(
    id: json['id'] as int?,
    recipientId: json['recipient_id'] as int?,
    message: json['message'] as String?,
    type: json['type'] as String? ?? 'General',
    isRead: json['is_read'] == 1,
    createdAt: json['created_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'recipient_id': recipientId,
    'message': message,
    'type': type,
    'is_read': isRead ? 1 : 0,
    'created_at': createdAt,
  };
}

// Ward model
class Ward {
  final int? id;
  final int? hospitalId;
  final String? wardNumber;
  final String? wardType;
  final String floor;
  final int totalBeds;
  final int occupiedBeds;
  final bool isActive;

  Ward({
    this.id,
    this.hospitalId,
    this.wardNumber,
    this.wardType,
    this.floor = '1',
    this.totalBeds = 10,
    this.occupiedBeds = 0,
    this.isActive = true,
  });

  factory Ward.fromMap(Map<String, dynamic> json) => Ward(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    wardNumber: json['ward_number'] as String?,
    wardType: json['ward_type'] as String?,
    floor: json['floor'] as String? ?? '1',
    totalBeds: json['total_beds'] as int? ?? 10,
    occupiedBeds: json['occupied_beds'] as int? ?? 0,
    isActive: json['is_active'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'ward_number': wardNumber,
    'ward_type': wardType,
    'floor': floor,
    'total_beds': totalBeds,
    'occupied_beds': occupiedBeds,
    'is_active': isActive ? 1 : 0,
  };

  int get availableBeds => totalBeds - occupiedBeds;
}

// PatientAdmission model
class PatientAdmission {
  final int? id;
  final int? patientId;
  final int? hospitalId;
  final int? wardId;
  final String? bedNumber;
  final String? admissionReason;
  final int? admittingDoctorId;
  final String? admissionDate;
  final String? dischargeDate;
  final String? status;
  final bool isSerious;
  final double totalBill;
  final double billPaid;

  PatientAdmission({
    this.id,
    this.patientId,
    this.hospitalId,
    this.wardId,
    this.bedNumber,
    this.admissionReason,
    this.admittingDoctorId,
    this.admissionDate,
    this.dischargeDate,
    this.status,
    this.isSerious = false,
    this.totalBill = 0.00,
    this.billPaid = 0.00,
  });

  factory PatientAdmission.fromMap(Map<String, dynamic> json) =>
      PatientAdmission(
        id: json['id'] as int?,
        patientId: json['patient_id'] as int?,
        hospitalId: json['hospital_id'] as int?,
        wardId: json['ward_id'] as int?,
        bedNumber: json['bed_number'] as String?,
        admissionReason: json['admission_reason'] as String?,
        admittingDoctorId: json['admitting_doctor_id'] as int?,
        admissionDate: json['admission_date'] as String?,
        dischargeDate: json['discharge_date'] as String?,
        status: json['status'] as String?,
        isSerious: json['is_serious'] == 1,
        totalBill: (json['total_bill'] as num?)?.toDouble() ?? 0.00,
        billPaid: (json['bill_paid'] as num?)?.toDouble() ?? 0.00,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'hospital_id': hospitalId,
    'ward_id': wardId,
    'bed_number': bedNumber,
    'admission_reason': admissionReason,
    'admitting_doctor_id': admittingDoctorId,
    'admission_date': admissionDate,
    'discharge_date': dischargeDate,
    'status': status,
    'is_serious': isSerious ? 1 : 0,
    'total_bill': totalBill,
    'bill_paid': billPaid,
  };
}

// EmergencyCase model
class EmergencyCase {
  final int? id;
  final int? hospitalId;
  final String? patientName;
  final String? symptoms;
  final String? severity;
  final int? assignedTo;
  final String? status;
  final String? createdAt;

  EmergencyCase({
    this.id,
    this.hospitalId,
    this.patientName,
    this.symptoms,
    this.severity,
    this.assignedTo,
    this.status,
    this.createdAt,
  });

  factory EmergencyCase.fromMap(Map<String, dynamic> json) => EmergencyCase(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    patientName: json['patient_name'] as String?,
    symptoms: json['symptoms'] as String?,
    severity: json['severity'] as String?,
    assignedTo: json['assigned_to'] as int?,
    status: json['status'] as String?,
    createdAt: json['created_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'patient_name': patientName,
    'symptoms': symptoms,
    'severity': severity,
    'assigned_to': assignedTo,
    'status': status,
    'created_at': createdAt,
  };
}

// Ambulance model
class Ambulance {
  final int? id;
  final int? hospitalId;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? status;
  final String? driverName;
  final String? driverPhone;
  final String? dispatchTime;
  final String? destination;
  final String? eta;
  final bool isActive;

  Ambulance({
    this.id,
    this.hospitalId,
    this.vehicleNumber,
    this.vehicleType,
    this.status,
    this.driverName,
    this.driverPhone,
    this.dispatchTime,
    this.destination,
    this.eta,
    this.isActive = true,
  });

  factory Ambulance.fromMap(Map<String, dynamic> json) => Ambulance(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    vehicleNumber: json['vehicle_number'] as String?,
    vehicleType: json['vehicle_type'] as String?,
    status: json['status'] as String?,
    driverName: json['driver_name'] as String?,
    driverPhone: json['driver_phone'] as String?,
    dispatchTime: json['dispatch_time'] as String?,
    destination: json['destination'] as String?,
    eta: json['eta'] as String?,
    isActive: json['is_active'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'vehicle_number': vehicleNumber,
    'vehicle_type': vehicleType,
    'status': status,
    'driver_name': driverName,
    'driver_phone': driverPhone,
    'dispatch_time': dispatchTime,
    'destination': destination,
    'eta': eta,
    'is_active': isActive ? 1 : 0,
  };
}

class Department {
  final int? id;
  final int? hospitalId;
  final String? name;
  final String? description;
  final String? floor;
  final String? phone;
  final int? headDoctorId;
  final double avgWaitMinutes;
  final String status;

  Department({
    this.id,
    this.hospitalId,
    this.name,
    this.description,
    this.floor,
    this.phone,
    this.headDoctorId,
    this.avgWaitMinutes = 0.00,
    this.status = 'Active',
  });

  factory Department.fromMap(Map<String, dynamic> json) => Department(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    name: json['name'] as String?,
    description: json['description'] as String?,
    floor: json['floor'] as String?,
    phone: json['phone'] as String?,
    headDoctorId: json['head_doctor_id'] as int?,
    avgWaitMinutes: (json['avg_wait_minutes'] as num?)?.toDouble() ?? 0.00,
    status: json['status'] as String? ?? 'Active',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'name': name,
    'description': description,
    'floor': floor,
    'phone': phone,
    'head_doctor_id': headDoctorId,
    'avg_wait_minutes': avgWaitMinutes,
    'status': status,
  };

  Department copyWith({
    int? id,
    int? hospitalId,
    String? name,
    String? description,
    String? floor,
    String? phone,
    int? headDoctorId,
    double? avgWaitMinutes,
    String? status,
  }) {
    return Department(
      id: id ?? this.id,
      hospitalId: hospitalId ?? this.hospitalId,
      name: name ?? this.name,
      description: description ?? this.description,
      floor: floor ?? this.floor,
      phone: phone ?? this.phone,
      headDoctorId: headDoctorId ?? this.headDoctorId,
      avgWaitMinutes: avgWaitMinutes ?? this.avgWaitMinutes,
      status: status ?? this.status,
    );
  }
}

class Bill {
  final int? id;
  final int? patientId;
  final int? hospitalId;
  final String? billNumber;
  final double amount;
  final double paidAmount;
  final String? status;
  final String? createdAt;
  final String? dueDate;

  Bill({
    this.id,
    this.patientId,
    this.hospitalId,
    this.billNumber,
    this.amount = 0.00,
    this.paidAmount = 0.00,
    this.status = 'Pending',
    this.createdAt,
    this.dueDate,
  });

  factory Bill.fromMap(Map<String, dynamic> json) => Bill(
    id: json['id'] as int?,
    patientId: json['patient_id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    billNumber: json['bill_number'] as String?,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.00,
    paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.00,
    status: json['status'] as String? ?? 'Pending',
    createdAt: json['created_at'] as String?,
    dueDate: json['due_date'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'hospital_id': hospitalId,
    'bill_number': billNumber,
    'amount': amount,
    'paid_amount': paidAmount,
    'status': status,
    'created_at': createdAt,
    'due_date': dueDate,
  };
}

class QueueEntry {
  final int? id;
  final int? hospitalId;
  final int? departmentId;
  final int? patientId;
  final int? doctorId;
  final int tokenNumber;
  final String? status;
  final String? createdAt;
  final String? calledAt;

  QueueEntry({
    this.id,
    this.hospitalId,
    this.departmentId,
    this.patientId,
    this.doctorId,
    this.tokenNumber = 0,
    this.status = 'Waiting',
    this.createdAt,
    this.calledAt,
  });

  factory QueueEntry.fromMap(Map<String, dynamic> json) => QueueEntry(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    departmentId: json['department_id'] as int?,
    patientId: json['patient_id'] as int?,
    doctorId: json['doctor_id'] as int?,
    tokenNumber: json['token_number'] as int? ?? 0,
    status: json['status'] as String? ?? 'Waiting',
    createdAt: json['created_at'] as String?,
    calledAt: json['called_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'department_id': departmentId,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'token_number': tokenNumber,
    'status': status,
    'created_at': createdAt,
    'called_at': calledAt,
  };
}

class StaffTask {
  final int? id;
  final int? hospitalId;
  final int? assignedTo;
  final String? title;
  final String? description;
  final String? status;
  final String? dueDate;
  final String? priority;

  StaffTask({
    this.id,
    this.hospitalId,
    this.assignedTo,
    this.title,
    this.description,
    this.status = 'Pending',
    this.dueDate,
    this.priority = 'Normal',
  });

  factory StaffTask.fromMap(Map<String, dynamic> json) => StaffTask(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    assignedTo: json['assigned_to'] as int?,
    title: json['title'] as String?,
    description: json['description'] as String?,
    status: json['status'] as String? ?? 'Pending',
    dueDate: json['due_date'] as String?,
    priority: json['priority'] as String? ?? 'Normal',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'assigned_to': assignedTo,
    'title': title,
    'description': description,
    'status': status,
    'due_date': dueDate,
    'priority': priority,
  };
}

class Bed {
  final int? id;
  final int? hospitalId;
  final int? wardId;
  final String? bedNumber;
  final String? status;
  final int? patientId;

  Bed({
    this.id,
    this.hospitalId,
    this.wardId,
    this.bedNumber,
    this.status = 'Available',
    this.patientId,
  });

  factory Bed.fromMap(Map<String, dynamic> json) => Bed(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    wardId: json['ward_id'] as int?,
    bedNumber: json['bed_number'] as String?,
    status: json['status'] as String? ?? 'Available',
    patientId: json['patient_id'] as int?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'ward_id': wardId,
    'bed_number': bedNumber,
    'status': status,
    'patient_id': patientId,
  };
}

class AuditEntry {
  final int? id;
  final int? userId;
  final String? action;
  final String? entityType;
  final int? entityId;
  final String? details;
  final String? createdAt;

  AuditEntry({
    this.id,
    this.userId,
    this.action,
    this.entityType,
    this.entityId,
    this.details,
    this.createdAt,
  });

  factory AuditEntry.fromMap(Map<String, dynamic> json) => AuditEntry(
    id: json['id'] as int?,
    userId: json['user_id'] as int?,
    action: json['action'] as String?,
    entityType: json['entity_type'] as String?,
    entityId: json['entity_id'] as int?,
    details: json['details'] as String?,
    createdAt: json['created_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'action': action,
    'entity_type': entityType,
    'entity_id': entityId,
    'details': details,
    'created_at': createdAt,
  };
}

class Stat {
  final int? id;
  final int? hospitalId;
  final String? metricKey;
  final double metricValue;
  final String? recordedAt;

  Stat({
    this.id,
    this.hospitalId,
    this.metricKey,
    this.metricValue = 0.00,
    this.recordedAt,
  });

  factory Stat.fromMap(Map<String, dynamic> json) => Stat(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    metricKey: json['metric_key'] as String?,
    metricValue: (json['metric_value'] as num?)?.toDouble() ?? 0.00,
    recordedAt: json['recorded_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'metric_key': metricKey,
    'metric_value': metricValue,
    'recorded_at': recordedAt,
  };
}

class DeptLoad {
  final int? id;
  final int? hospitalId;
  final int? departmentId;
  final int patientCount;
  final int doctorCount;
  final double occupancyRate;
  final String? recordedAt;

  DeptLoad({
    this.id,
    this.hospitalId,
    this.departmentId,
    this.patientCount = 0,
    this.doctorCount = 0,
    this.occupancyRate = 0.00,
    this.recordedAt,
  });

  factory DeptLoad.fromMap(Map<String, dynamic> json) => DeptLoad(
    id: json['id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    departmentId: json['department_id'] as int?,
    patientCount: json['patient_count'] as int? ?? 0,
    doctorCount: json['doctor_count'] as int? ?? 0,
    occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0.00,
    recordedAt: json['recorded_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hospital_id': hospitalId,
    'department_id': departmentId,
    'patient_count': patientCount,
    'doctor_count': doctorCount,
    'occupancy_rate': occupancyRate,
    'recorded_at': recordedAt,
  };
}

Map<String, dynamic> _decodeMap(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const {};
  try {
    final value = jsonDecode(encoded);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  } catch (_) {}
  return const {};
}

List<String> _decodeStrings(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const [];
  try {
    final value = jsonDecode(encoded);
    if (value is List) return value.cast<String>();
  } catch (_) {
    return encoded
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
  return const [];
}

List<int> _decodeInts(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const [];
  try {
    final value = jsonDecode(encoded);
    if (value is List) return value.cast<int>();
  } catch (_) {
    return encoded
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .toList();
  }
  return const [];
}
