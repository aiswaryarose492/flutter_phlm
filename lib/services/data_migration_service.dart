import 'dart:convert';

import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/models.dart';

class DataMigrationService {
  final DatabaseHelper db;

  DataMigrationService(this.db);

  Future<bool> importFromJson(String jsonPath) async {
    try {
      final String jsonString = await rootBundle.loadString(jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      if (jsonData.containsKey('users')) {
        for (final userJson in jsonData['users']) {
          await db.insertUser(
            User(
              username: userJson['username'],
              email: userJson['email'],
              firstName: userJson['first_name'],
              lastName: userJson['last_name'],
              isHospitalAdmin: userJson['is_hospital_admin'] ?? false,
              isDoctor: userJson['is_doctor'] ?? false,
              isPatient: userJson['is_patient'] ?? false,
              isLab: userJson['is_lab'] ?? false,
              isPharmacy: userJson['is_pharmacy'] ?? false,
              isStaffMember: userJson['is_staff_member'] ?? false,
            ),
          );
        }
      }

      if (jsonData.containsKey('hospitals')) {
        for (final hospitalJson in jsonData['hospitals']) {
          await db.insertHospital(
            Hospital(
              userId: hospitalJson['user_id'],
              name: hospitalJson['name'],
              address: hospitalJson['address'],
              maxLeaveDays: hospitalJson['max_leave_days'] ?? 12,
              extraLeaveDeduction:
                  (hospitalJson['extra_leave_deduction'] as num?)?.toDouble() ??
                  0.00,
            ),
          );
        }
      }

      if (jsonData.containsKey('doctors')) {
        for (final doctorJson in jsonData['doctors']) {
          await db.insertDoctor(
            Doctor(
              userId: doctorJson['user_id'],
              hospitalId: doctorJson['hospital_id'],
              specialty: doctorJson['specialty'],
              department: doctorJson['department'],
              experience: doctorJson['experience'] ?? 0,
              available: doctorJson['available'] ?? true,
              appointmentFees:
                  (doctorJson['appointment_fees'] as num?)?.toDouble() ?? 0.00,
              salary: (doctorJson['salary'] as num?)?.toDouble() ?? 0.00,
            ),
          );
        }
      }

      if (jsonData.containsKey('patients')) {
        for (final patientJson in jsonData['patients']) {
          await db.insertPatient(
            Patient(
              userId: patientJson['user_id'],
              hospitalId: patientJson['hospital_id'],
              phone: patientJson['phone'],
              dateOfBirth: patientJson['date_of_birth'],
              gender: patientJson['gender'] ?? 'Other',
              address: patientJson['address'],
            ),
          );
        }
      }

      if (jsonData.containsKey('appointments')) {
        for (final apptJson in jsonData['appointments']) {
          await db.insertAppointment(
            Appointment(
              doctorId: apptJson['doctor_id'],
              patientId: apptJson['patient_id'],
              date: apptJson['date'],
              time: apptJson['time'],
              symptoms: apptJson['symptoms'],
              status: apptJson['status'] ?? 'Pending',
            ),
          );
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> exportToJson() async {
    final exportData = <String, dynamic>{};

    exportData['users'] = await db.getAllUsers();
    exportData['hospitals'] = await db.getAllHospitals();
    exportData['doctors'] = await db.getAllDoctors();
    exportData['patients'] = await db.getAllPatients();
    exportData['appointments'] = await db.getAllAppointments();
    exportData['prescriptions'] = await db.getAllPrescriptions();
    exportData['reminders'] = await db.getAllReminders();
    exportData['lab_reports'] = await db.getAllLabReports();
    exportData['medicines'] = await db.getAllMedicines();
    exportData['notifications'] = await db.getAllNotifications();

    return exportData;
  }
}
