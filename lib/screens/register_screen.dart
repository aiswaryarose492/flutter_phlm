import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/patient.dart';
import '../models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDob;
  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;
  String? _usernameError;

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  void _checkPasswordStrength(String p) {
    var score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    setState(() {
      if (score <= 1) {
        _passwordStrength = 'Weak';
        _strengthColor = Colors.red;
      } else if (score <= 3) {
        _passwordStrength = 'Medium';
        _strengthColor = Colors.orange;
      } else {
        _passwordStrength = 'Strong';
        _strengthColor = Colors.green;
      }
    });
  }

  Future<bool> _isUsernameTaken(String username) async {
    final db = await DatabaseHelper().database;
    final res = await db.query(
      'users',
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [username.trim()],
    );
    return res.isNotEmpty;
  }

  Future<void> _register() async {
    setState(() => _usernameError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final taken = await _isUsernameTaken(_usernameCtrl.text);
    if (taken) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _usernameError = 'This username is already taken. Choose another.';
      });
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      final userId = await dbHelper.insertUser(
        User(
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          isPatient: true,
        ),
      );

      await dbHelper.insertPatient(
        Patient(
          userId: userId,
          hospitalId: 1,
          phone: _phoneCtrl.text.trim(),
          dateOfBirth: _selectedDob != null
              ? '${_selectedDob!.year}-'
                    '${_selectedDob!.month.toString().padLeft(2, '0')}-'
                    '${_selectedDob!.day.toString().padLeft(2, '0')}'
              : null,
          gender: _selectedGender,
          address: _addressCtrl.text.trim(),
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please sign in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_add,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Create Patient Account',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Register to book appointments and manage your health',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _sectionHeader('Personal Information'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'First Name *',
                              ),
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Last Name *',
                              ),
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dobCtrl,
                        readOnly: true,
                        onTap: _pickDob,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth *',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          hintText: 'DD/MM/YYYY',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Date of birth is required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                        ),
                        items: ['Male', 'Female', 'Other']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGender = v),
                        validator: (v) => v == null ? 'Select gender' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Phone number is required';
                          if (v.length < 10) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader('Account Credentials'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Username *',
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: 'Min 4 characters, no spaces',
                          errorText: _usernameError,
                        ),
                        onChanged: (_) {
                          if (_usernameError != null) {
                            setState(() => _usernameError = null);
                          }
                        },
                        validator: (v) {
                          if (v!.trim().isEmpty) return 'Username is required';
                          if (v.trim().length < 4) {
                            return 'Minimum 4 characters';
                          }
                          if (v.contains(' ')) return 'No spaces allowed';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Email is required';
                          if (!RegExp(
                            r'^[\w\.-]+@[\w\.-]+\.\w+$',
                          ).hasMatch(v)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        onChanged: _checkPasswordStrength,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      if (_passwordCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const SizedBox(width: 4),
                            Text(
                              'Strength: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _passwordStrength,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _strengthColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Please confirm your password';
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader('Address (Optional)'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Full Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Already have an account? Sign In'),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3C5E),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
