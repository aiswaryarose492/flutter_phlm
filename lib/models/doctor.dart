// Doctor model
class Doctor {
  final int? id;
  final int? userId;
  final int? hospitalId;
  final String? specialty;
  final String? department;
  final String? imagePath;
  final String? qualification;
  final int experience;
  final String? bio;
  final bool available;
  final String? availableDays;
  final String? availableStartTime;
  final String? availableEndTime;
  final String? breakStartTime;
  final String? breakEndTime;
  final int maxAppointmentsPerDay;
  final double appointmentFees;
  final double salary;
  final String salaryFrequency;
  final String? name;
  final String? phone;
  final String? email;
  final String status;

  Doctor({
    this.id,
    this.userId,
    this.hospitalId,
    this.specialty,
    this.department,
    this.imagePath,
    this.qualification,
    this.experience = 0,
    this.bio,
    this.available = true,
    this.availableDays,
    this.availableStartTime,
    this.availableEndTime,
    this.breakStartTime,
    this.breakEndTime,
    this.maxAppointmentsPerDay = 10,
    this.appointmentFees = 0.00,
    this.salary = 0.00,
    this.salaryFrequency = 'Monthly',
    this.name,
    this.phone,
    this.email,
    this.status = 'Active',
  });

  factory Doctor.fromMap(Map<String, dynamic> json) => Doctor(
    id: json['id'] as int?,
    userId: json['user_id'] as int?,
    hospitalId: json['hospital_id'] as int?,
    specialty: json['specialty'] as String?,
    department: json['department'] as String?,
    imagePath: json['image_path'] as String?,
    qualification: json['qualification'] as String?,
    experience: json['experience'] as int? ?? 0,
    bio: json['bio'] as String?,
    available: json['available'] == 1,
    availableDays: json['available_days'] as String?,
    availableStartTime: json['available_start_time'] as String?,
    availableEndTime: json['available_end_time'] as String?,
    breakStartTime: json['break_start_time'] as String?,
    breakEndTime: json['break_end_time'] as String?,
    maxAppointmentsPerDay: json['max_appointments_per_day'] as int? ?? 10,
    appointmentFees: (json['appointment_fees'] as num?)?.toDouble() ?? 0.00,
    salary: (json['salary'] as num?)?.toDouble() ?? 0.00,
    salaryFrequency: json['salary_frequency'] as String? ?? 'Monthly',
    name: json['name'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    status: json['status'] as String? ?? 'Active',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'hospital_id': hospitalId,
    'specialty': specialty,
    'department': department,
    'image_path': imagePath,
    'qualification': qualification,
    'experience': experience,
    'bio': bio,
    'available': available ? 1 : 0,
    'available_days': availableDays,
    'available_start_time': availableStartTime,
    'available_end_time': availableEndTime,
    'break_start_time': breakStartTime,
    'break_end_time': breakEndTime,
    'max_appointments_per_day': maxAppointmentsPerDay,
    'appointment_fees': appointmentFees,
    'salary': salary,
    'salary_frequency': salaryFrequency,
    'name': name,
    'phone': phone,
    'email': email,
    'status': status,
  };

  Doctor copyWith({
    int? id,
    int? userId,
    int? hospitalId,
    String? specialty,
    String? department,
    String? imagePath,
    String? qualification,
    int? experience,
    String? bio,
    bool? available,
    String? availableDays,
    String? availableStartTime,
    String? availableEndTime,
    String? breakStartTime,
    String? breakEndTime,
    int? maxAppointmentsPerDay,
    double? appointmentFees,
    double? salary,
    String? salaryFrequency,
    String? name,
    String? phone,
    String? email,
    String? status,
  }) {
    return Doctor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hospitalId: hospitalId ?? this.hospitalId,
      specialty: specialty ?? this.specialty,
      department: department ?? this.department,
      imagePath: imagePath ?? this.imagePath,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
      available: available ?? this.available,
      availableDays: availableDays ?? this.availableDays,
      availableStartTime: availableStartTime ?? this.availableStartTime,
      availableEndTime: availableEndTime ?? this.availableEndTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      maxAppointmentsPerDay:
          maxAppointmentsPerDay ?? this.maxAppointmentsPerDay,
      appointmentFees: appointmentFees ?? this.appointmentFees,
      salary: salary ?? this.salary,
      salaryFrequency: salaryFrequency ?? this.salaryFrequency,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }
}
