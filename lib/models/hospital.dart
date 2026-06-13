// Hospital model
class Hospital {
  final int? id;
  final int? userId;
  final String? name;
  final String? address;
  final int maxLeaveDays;
  final double extraLeaveDeduction;
  final double? latitude;
  final double? longitude;
  final String? allowedIpAddress;
  final String? emergencyNumber;

  Hospital({
    this.id,
    this.userId,
    this.name,
    this.address,
    this.maxLeaveDays = 12,
    this.extraLeaveDeduction = 0.00,
    this.latitude,
    this.longitude,
    this.allowedIpAddress,
    this.emergencyNumber,
  });

  factory Hospital.fromMap(Map<String, dynamic> json) => Hospital(
    id: json['id'] as int?,
    userId: json['user_id'] as int?,
    name: json['name'] as String?,
    address: json['address'] as String?,
    maxLeaveDays: json['max_leave_days'] as int? ?? 12,
    extraLeaveDeduction:
        (json['extra_leave_deduction'] as num?)?.toDouble() ?? 0.00,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    allowedIpAddress: json['allowed_ip_address'] as String?,
    emergencyNumber: json['emergency_number'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'address': address,
    'max_leave_days': maxLeaveDays,
    'extra_leave_deduction': extraLeaveDeduction,
    'latitude': latitude,
    'longitude': longitude,
    'allowed_ip_address': allowedIpAddress,
    'emergency_number': emergencyNumber,
  };
}
