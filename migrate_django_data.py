#!/usr/bin/env python
"""
Django to Flutter Data Migration Script
This script exports data from your Django SQLite database to JSON format
compatible with the Flutter app.
"""
import sqlite3
import json
from datetime import datetime

def migrate_django_to_flutter(django_db_path='db.sqlite3', output_file='flutter_data.json'):
    conn = sqlite3.connect(django_db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    flutter_data = {}
    
    # Export Users
    cursor.execute("SELECT * FROM core_user")
    users = []
    for row in cursor.fetchall():
        users.append({
            'id': row['id'],
            'username': row['username'],
            'email': row['email'],
            'first_name': row['first_name'],
            'last_name': row['last_name'],
            'is_hospital_admin': bool(row['is_hospital_admin']),
            'is_doctor': bool(row['is_doctor']),
            'is_patient': bool(row['is_patient']),
            'is_lab': bool(row['is_lab']),
            'is_pharmacy': bool(row['is_pharmacy']),
            'is_staff_member': bool(row['is_staff_member']),
            'password': row['password'],  # Note: Django stores hashed passwords
        })
    flutter_data['users'] = users
    
    # Export Hospitals
    try:
        cursor.execute("SELECT * FROM core_hospital")
        hospitals = []
        for row in cursor.fetchall():
            hospitals.append({
                'id': row['id'],
                'user_id': row['user_id'],
                'name': row['name'],
                'address': row['address'],
                'max_leave_days': row['max_leave_days'],
                'extra_leave_deduction': row['extra_leave_deduction'],
            })
        flutter_data['hospitals'] = hospitals
    except:
        pass
    
    # Export Doctors
    try:
        cursor.execute("SELECT * FROM core_doctor")
        doctors = []
        for row in cursor.fetchall():
            doctors.append({
                'id': row['id'],
                'user_id': row['user_id'],
                'hospital_id': row['hospital_id'],
                'specialty': row['specialty'],
                'department': row['department'],
                'experience': row['experience'],
                'available': bool(row['available']),
                'appointment_fees': row['appointment_fees'],
                'salary': row['salary'],
            })
        flutter_data['doctors'] = doctors
    except:
        pass
    
    # Export Patients
    try:
        cursor.execute("SELECT * FROM core_patient")
        patients = []
        for row in cursor.fetchall():
            patients.append({
                'id': row['id'],
                'user_id': row['user_id'],
                'hospital_id': row['hospital_id'],
                'phone': row['phone'],
                'date_of_birth': row['date_of_birth'],
                'gender': row['gender'],
                'address': row['address'],
                'water_goal': row['water_goal'],
            })
        flutter_data['patients'] = patients
    except:
        pass
    
    # Export Appointments
    try:
        cursor.execute("SELECT * FROM core_appointment")
        appointments = []
        for row in cursor.fetchall():
            appointments.append({
                'id': row['id'],
                'doctor_id': row['doctor_id'],
                'patient_id': row['patient_id'],
                'date': row['date'],
                'time': row['time'],
                'symptoms': row['symptoms'],
                'status': row['status'],
            })
        flutter_data['appointments'] = appointments
    except:
        pass
    
    # Export all other models...
    # (Prescriptions, Medicines, Wards, etc.)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(flutter_data, f, indent=2, default=str)
    
    conn.close()
    print(f"Migration complete. Data saved to {output_file}")

if __name__ == '__main__':
    migrate_django_to_flutter()