import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../database/database_helper.dart';
import '../models/models.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _db = DatabaseHelper();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'phlm_channel',
          'PHLM Notifications',
          channelDescription: 'Hospital reminders and alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleDailyMedicationReminders() async {
    final prescriptions = await _db.getAllPrescriptions();
    for (final prescription in prescriptions) {
      final rows = _decodeRows(prescription.medicines);
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final frequency = row['frequency'] as String? ?? 'OD';
        final time = _timeForFrequency(frequency);
        final name = row['name'] as String? ?? 'Medication';
        await _plugin.zonedSchedule(
          1000 + ((prescription.id ?? 0) * 100) + index,
          'Medication reminder',
          'Time for $name ($frequency)',
          _nextInstanceOf(time),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_channel',
              'Medication Reminders',
              channelDescription: 'Daily medication reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  Future<void> scheduleAppointmentReminders() async {
    final appointments = await _db.getAllAppointments();
    for (final appointment in appointments) {
      final at = _appointmentTime(appointment);
      if (at == null) continue;
      await _plugin.zonedSchedule(
        2000 + (appointment.id ?? 0),
        'Appointment reminder',
        'Your appointment is in 1 hour.',
        at.subtract(const Duration(hours: 1)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_channel',
            'Appointment Reminders',
            channelDescription: 'Appointment reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> showLowStockAlerts() async {
    final medicines = await _db.getAllMedicines();
    for (final medicine in medicines) {
      if (medicine.stockQuantity <= medicine.reorderLevel) {
        await showNotification(
          id: 3000 + (medicine.id ?? 0),
          title: 'Low stock alert',
          body: '${medicine.name ?? 'Medicine'} stock is low.',
        );
      }
    }
  }

  Future<void> showLabResultReadyAlerts() async {
    final reports = await _db.getAllLabReports();
    for (final report in reports) {
      if (report.patientVisible) {
        await showNotification(
          id: 4000 + (report.id ?? 0),
          title: 'Lab result ready',
          body: 'Your lab result is available.',
        );
      }
    }
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  TimeOfDay _timeForFrequency(String frequency) {
    switch (frequency.toUpperCase()) {
      case 'BD':
        return const TimeOfDay(hour: 8, minute: 0);
      case 'TDS':
        return const TimeOfDay(hour: 9, minute: 0);
      case 'QID':
        return const TimeOfDay(hour: 7, minute: 0);
      case 'OD':
      default:
        return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  tz.TZDateTime? _appointmentTime(Appointment appointment) {
    final date = DateTime.tryParse(appointment.date ?? '');
    if (date == null) return null;
    final timeParts = (appointment.time ?? '09:00').split(':');
    final hour = int.tryParse(timeParts.first) ?? 9;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  List<Map<String, dynamic>> _decodeRows(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final value = jsonDecode(encoded);
      if (value is List) return value.cast<Map<String, dynamic>>();
    } catch (_) {}
    return const [];
  }
}
