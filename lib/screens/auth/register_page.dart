import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/sign_in_service.dart'; // Ensure this path is correct

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String _role = 'worker';
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Manual Email/Password Registration
  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': _role,
        'points': 0,
        'reliability': 100,
        'skills': _role == 'worker' ? ['Barista'] : [],
        'stats': {'lateCancellations': 0, 'shiftsCompleted': 0},
        'createdAt': FieldValue.serverTimestamp(),
        'savedShifts': [],
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Registration failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Google Registration logic
  Future<void> _registerWithGoogle() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // Passes the currently selected _role to the service
      await GoogleSignInService.instance.signInWithGoogle(role: _role);
    } catch (e) {
      setState(() => _error = 'Google registration failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_nameCtrl, 'Full Name'),
                  const SizedBox(height: 16),
                  _buildTextField(_emailCtrl, 'Email'),
                  const SizedBox(height: 16),
                  _buildTextField(_passCtrl, 'Password', isObscure: true),
                  const SizedBox(height: 16),
                  _buildRoleSelector(),
                  if (_error.isNotEmpty) _buildErrorText(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildGoogleButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isObscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        const Text('Register as:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _role,
          items: const [
            DropdownMenuItem(value: 'worker', child: Text('Worker')),
            DropdownMenuItem(value: 'employer', child: Text('Employer')),
          ],
          onChanged: _loading ? null : (v) => setState(() => _role = v!),
        ),
      ],
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(_error, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _register,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        child: _loading ? const CircularProgressIndicator() : const Text('Register'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider()),
        Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('OR')),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _registerWithGoogle,
        icon: const Icon(Icons.account_circle_outlined),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    );
  }
}