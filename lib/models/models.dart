import 'extended_models.dart';

export 'user.dart';
export 'hospital.dart';
export 'doctor.dart';
export 'patient.dart';
export 'appointment.dart';
export 'extended_models.dart';

enum UserRole {
  admin,
  doctor,
  patient,
  staff,
  lab,
  pharmacy,
  guest;

  bool get canAccessDashboard => this != guest;

  String get path {
    switch (this) {
      case UserRole.admin:
        return '/admin';
      case UserRole.doctor:
        return '/doctor';
      case UserRole.patient:
        return '/patient';
      case UserRole.staff:
        return '/staff';
      case UserRole.lab:
        return '/lab';
      case UserRole.pharmacy:
        return '/pharmacy';
      case UserRole.guest:
        return '/';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.patient:
        return 'Patient';
      case UserRole.staff:
        return 'Staff';
      case UserRole.lab:
        return 'Lab';
      case UserRole.pharmacy:
        return 'Pharmacy';
      case UserRole.guest:
        return 'Guest';
    }
  }
}

UserRole userRoleFromFlags({
  required bool isHospitalAdmin,
  required bool isDoctor,
  required bool isPatient,
  required bool isStaffMember,
  required bool isLab,
  required bool isPharmacy,
}) {
  if (isHospitalAdmin) return UserRole.admin;
  if (isDoctor) return UserRole.doctor;
  if (isPatient) return UserRole.patient;
  if (isStaffMember) return UserRole.staff;
  if (isLab) return UserRole.lab;
  if (isPharmacy) return UserRole.pharmacy;
  return UserRole.guest;
}

typedef AppNotification = Notification;
