import 'models.dart';

class User {
  final int? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? password;
  final bool isHospitalAdmin;
  final bool isDoctor;
  final bool isPatient;
  final bool isLab;
  final bool isPharmacy;
  final bool isStaffMember;
  final bool isBlocked;
  final String? lastLogin;
  final int? linkedEntityId;

  User({
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.password,
    this.isHospitalAdmin = false,
    this.isDoctor = false,
    this.isPatient = false,
    this.isLab = false,
    this.isPharmacy = false,
    this.isStaffMember = false,
    this.isBlocked = false,
    this.lastLogin,
    this.linkedEntityId,
  });

  factory User.fromMap(Map<String, dynamic> json) => User(
    id: json['id'] as int?,
    username: json['username'] as String?,
    email: json['email'] as String?,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    password: json['password'] as String?,
    isHospitalAdmin: _toBool(json['is_hospital_admin']),
    isDoctor: _toBool(json['is_doctor']),
    isPatient: _toBool(json['is_patient']),
    isLab: _toBool(json['is_lab']),
    isPharmacy: _toBool(json['is_pharmacy']),
    isStaffMember: _toBool(json['is_staff_member']),
    isBlocked: _toBool(json['is_blocked']),
    lastLogin: json['last_login'] as String?,
    linkedEntityId: json['linked_entity_id'] as int?,
  );

  UserRole get role => userRoleFromFlags(
    isHospitalAdmin: isHospitalAdmin,
    isDoctor: isDoctor,
    isPatient: isPatient,
    isStaffMember: isStaffMember,
    isLab: isLab,
    isPharmacy: isPharmacy,
  );

  bool get hasDashboardRole => role.canAccessDashboard;

  static bool _toBool(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'password': password,
    'is_hospital_admin': isHospitalAdmin ? 1 : 0,
    'is_doctor': isDoctor ? 1 : 0,
    'is_patient': isPatient ? 1 : 0,
    'is_lab': isLab ? 1 : 0,
    'is_pharmacy': isPharmacy ? 1 : 0,
    'is_staff_member': isStaffMember ? 1 : 0,
    'is_blocked': isBlocked ? 1 : 0,
    'last_login': lastLogin,
    'linked_entity_id': linkedEntityId,
  };

  String getFullName() {
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? password,
    bool? isHospitalAdmin,
    bool? isDoctor,
    bool? isPatient,
    bool? isLab,
    bool? isPharmacy,
    bool? isStaffMember,
    bool? isBlocked,
    String? lastLogin,
    int? linkedEntityId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      password: password ?? this.password,
      isHospitalAdmin: isHospitalAdmin ?? this.isHospitalAdmin,
      isDoctor: isDoctor ?? this.isDoctor,
      isPatient: isPatient ?? this.isPatient,
      isLab: isLab ?? this.isLab,
      isPharmacy: isPharmacy ?? this.isPharmacy,
      isStaffMember: isStaffMember ?? this.isStaffMember,
      isBlocked: isBlocked ?? this.isBlocked,
      lastLogin: lastLogin ?? this.lastLogin,
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
    );
  }
}
