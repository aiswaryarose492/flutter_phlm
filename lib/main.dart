import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'database/database_seeder.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screens.dart';
import 'screens/department_doctors_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseHelper().database;
  await DatabaseHelper().ensureMergeTables();
  final users = await db.query('users', limit: 1);
  if (users.isEmpty) {
    await DatabaseSeeder.seedDatabase();
  }
  await DatabaseSeeder.ensureSampleData();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const PHLMApp(),
    ),
  );
}

class PHLMApp extends StatelessWidget {
  const PHLMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHLMS Medical Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3C5E),
          primary: const Color(0xFF1A3C5E),
          secondary: const Color(0xFF00897B),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3C5E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/department_doctors': (_) => const DepartmentDoctorsScreen(),
        '/hospital_dashboard': (_) => const HospitalDashboardScreen(),
        '/doctor_dashboard': (_) => const DoctorDashboardScreen(),
        '/patient_dashboard': (_) => const PatientDashboardScreen(),
        '/lab_dashboard': (_) => const LabDashboardScreen(),
        '/pharmacy_dashboard': (_) => const PharmacyDashboardScreen(),
        '/staff_dashboard': (_) => const StaffDashboardScreen(),
      },
    );
  }
}
