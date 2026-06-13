// Patient model
class Patient {
  final int? id;
  final int? userId;
  final int? hospitalId;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? name;
  final String? photoPath;
  final int waterGoal;

  Patient({
    this.id,
    this.userId,
    this.hospitalId,
    this.phone,
    this.dateOfBirth,
    this.gender = 'Other',
    this.address,
    this.name,
    this.photoPath,
    this.waterGoal = 8,
  });

  factory Patient.fromMap(Map<String, dynamic> json) => Patient(
    id: json['id'] as int?,
    userId: json['user_id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    phone: json['phone'] as String?,
    dateOfBirth: json['date_of_birth'] as String?,
    gender: json['gender'] as String? ?? 'Other',
    address: json['address'] as String?,
    name: json['name'] as String?,
    photoPath: json['photo_path'] as String?,
    waterGoal: json['water_goal'] as int? ?? 8,
  );

  int? get age {
    final dob = DateTime.tryParse(dateOfBirth ?? '');
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'hospital_id': hospitalId,
    'phone': phone,
    'date_of_birth': dateOfBirth,
    'gender': gender,
    'address': address,
    'name': name,
    'photo_path': photoPath,
    'water_goal': waterGoal,
  };
}
