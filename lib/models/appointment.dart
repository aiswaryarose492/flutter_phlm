// Appointment model
class Appointment {
  final int? id;
  final int? doctorId;
  final int? patientId;
  final String? date;
  final String? time;
  final String? symptoms;
  final bool isOnline;
  final String? meetLink;
  final double appointmentFees;
  final String? status;
  final String? followUpDate;
  final bool reminderSent;

  Appointment({
    this.id,
    this.doctorId,
    this.patientId,
    this.date,
    this.time,
    this.symptoms,
    this.isOnline = false,
    this.meetLink,
    this.appointmentFees = 0.00,
    this.status,
    this.followUpDate,
    this.reminderSent = false,
  });

  factory Appointment.fromMap(Map<String, dynamic> json) => Appointment(
    id: json['id'] as int?,
    doctorId: json['doctor_id'] as int?,
    patientId: json['patient_id'] as int?,
    date: json['date'] as String?,
    time: json['time'] as String?,
    symptoms: json['symptoms'] as String?,
    isOnline: json['is_online'] == 1,
    meetLink: json['meet_link'] as String?,
    appointmentFees: (json['appointment_fees'] as num?)?.toDouble() ?? 0.00,
    status: json['status'] as String?,
    followUpDate: json['follow_up_date'] as String?,
    reminderSent: json['reminder_sent'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctor_id': doctorId,
    'patient_id': patientId,
    'date': date,
    'time': time,
    'symptoms': symptoms,
    'is_online': isOnline ? 1 : 0,
    'meet_link': meetLink,
    'appointment_fees': appointmentFees,
    'status': status,
    'follow_up_date': followUpDate,
    'reminder_sent': reminderSent ? 1 : 0,
  };
}
