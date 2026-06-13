# PHLM - Flutter Hospital Management

A Flutter mobile app converted from Django PHLM project with database migration support.

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── models.dart             # Barrel export for all models
│   ├── user.dart               # User model
│   ├── hospital.dart           # Hospital model
│   ├── doctor.dart             # Doctor model
│   ├── patient.dart            # Patient model
│   ├── appointment.dart        # Appointment model
│   └── extended_models.dart    # Medicine, Ward, Admission, etc.
├── database/
│   ├── database_helper.dart    # SQLite database setup & CRUD
│   ├── database_seeder.dart      # Sample data seeder
│   └── sqlite_migration_service.dart
├── services/
│   └── data_migration_service.dart  # Import/export migration service
├── providers/
│   └── auth_provider.dart        # Authentication state management
├── screens/
│   ├── home_screen.dart         # Main entry screen
│   ├── login_screen.dart        # Login screen
│   └── dashboard_screens.dart   # All role dashboards
└── widgets/                     # Reusable UI components
```

## Database Models (Converted from Django)

- User (with role flags: is_hospital_admin, is_doctor, is_patient, is_lab, is_pharmacy, is_staff_member)
- Hospital
- Doctor
- Patient
- Appointment
- Staff, LabWorker, PharmacyWorker
- Prescription, Reminder, LabReport
- Medicine (pharmacy module)
- Ward, PatientAdmission (inpatient module)
- EmergencyCase, Ambulance, AmbulanceCall

## Data Migration

### From Django to Flutter

Run the Python script in your Django project:

```bash
# In your Django project directory
python export_django_data.py
```

This creates `flutter_export.json` with all your data.

### Import into Flutter

The app loads data from `assets/flutter_data.json` on first launch.

## Setup Instructions

1. The Flutter project is already created with dependencies installed
2. Data has been exported from Django and copied to assets
3. Run the app:

```bash
cd flutter_phlm
flutter run
```

## Architecture

- Uses `sqflite` for local SQLite database
- `provider` for state management
- `http` for potential API integration
- Follows Material 3 design

## Notes

- Passwords: Django stores hashed passwords, Flutter stores plain (consider OAuth/API sync for production)
- Images: Stored as file paths in Flutter, FileField in Django
- DateTime: Stored as ISO strings in SQLite
- Foreign keys: Maintained as integer references