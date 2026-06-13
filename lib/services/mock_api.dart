import '../models/models.dart';

class MockApi {
  static final MockApi _instance = MockApi._internal();
  factory MockApi() => _instance;
  MockApi._internal();

  Future<List<Department>> getDepartments() async {
    return [
      Department(
        id: 1,
        hospitalId: 1,
        name: 'Cardiology',
        description: 'Heart and vascular care',
        floor: '2',
        phone: '555-2001',
      ),
      Department(
        id: 2,
        hospitalId: 1,
        name: 'Pediatrics',
        description: 'Child health services',
        floor: '3',
        phone: '555-2002',
      ),
      Department(
        id: 3,
        hospitalId: 1,
        name: 'Dermatology',
        description: 'Skin and allergy care',
        floor: '2',
        phone: '555-2003',
      ),
      Department(
        id: 4,
        hospitalId: 1,
        name: 'Neurology',
        description: 'Brain and nerve care',
        floor: '4',
        phone: '555-2004',
      ),
      Department(
        id: 5,
        hospitalId: 1,
        name: 'Orthopedics',
        description: 'Bone and joint care',
        floor: '1',
        phone: '555-2005',
      ),
    ];
  }

  Future<List<Doctor>> getDoctors() async {
    return [
      Doctor(
        id: 1,
        userId: 2,
        hospitalId: 1,
        specialty: 'Cardiology',
        department: 'Cardiology',
        experience: 10,
        available: true,
        appointmentFees: 500,
      ),
      Doctor(
        id: 2,
        userId: 2,
        hospitalId: 1,
        specialty: 'Pediatrics',
        department: 'Pediatrics',
        experience: 8,
        available: true,
        appointmentFees: 400,
      ),
      Doctor(
        id: 3,
        userId: 2,
        hospitalId: 1,
        specialty: 'Dermatology',
        department: 'Dermatology',
        experience: 6,
        available: true,
        appointmentFees: 450,
      ),
      Doctor(
        id: 4,
        userId: 2,
        hospitalId: 1,
        specialty: 'Neurology',
        department: 'Neurology',
        experience: 12,
        available: true,
        appointmentFees: 600,
      ),
      Doctor(
        id: 5,
        userId: 2,
        hospitalId: 1,
        specialty: 'Orthopedics',
        department: 'Orthopedics',
        experience: 9,
        available: true,
        appointmentFees: 500,
      ),
    ];
  }

  Future<List<Appointment>> getAppointments() async {
    return [
      Appointment(
        id: 1,
        doctorId: 1,
        patientId: 1,
        date: DateTime.now().add(const Duration(days: 2)).toString(),
        time: '10:00',
        symptoms: 'Chest discomfort',
        isOnline: false,
        status: 'Booked',
      ),
    ];
  }

  Future<List<LabReport>> getLabReports() async {
    return [
      LabReport(
        id: 1,
        patientId: 1,
        doctorId: 1,
        hospitalId: 1,
        title: 'CBC Test',
        testType: 'Blood',
        result: 'Normal',
        uploadedAt: DateTime.now().subtract(const Duration(days: 3)).toString(),
      ),
    ];
  }

  Future<List<Prescription>> getPrescriptions() async {
    return [
      Prescription(
        id: 1,
        appointmentId: 1,
        medicines: 'Paracetamol 500mg',
        notes: 'Take after food',
        createdAt: DateTime.now().subtract(const Duration(days: 2)).toString(),
      ),
    ];
  }

  Future<List<Bill>> getBills() async {
    return [
      Bill(
        id: 1,
        patientId: 1,
        hospitalId: 1,
        billNumber: 'BL-1001',
        amount: 2500,
        paidAmount: 1000,
        status: 'Partially Paid',
        createdAt: DateTime.now().toString(),
      ),
    ];
  }

  Future<List<Hospital>> getHospitals() async {
    return [
      Hospital(
        id: 1,
        name: 'General Hospital',
        address: '123 Main St, City',
        maxLeaveDays: 12,
        extraLeaveDeduction: 100,
        emergencyNumber: '108',
      ),
    ];
  }
}
