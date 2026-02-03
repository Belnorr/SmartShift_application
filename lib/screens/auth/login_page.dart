import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sign_in_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // State Variables
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Handles standard Email/Password authentication
  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // No Navigator needed: RootGate will catch the auth change
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Handles Google Sign-In via the service instance
  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // This service handles both Auth and Firestore document checking
      await GoogleSignInService.instance.signInWithGoogle();
      
      // IMPORTANT: We do not use Navigator here. 
      // RootGate's StreamBuilder detects the login and shows RoleRouter.
    } catch (e) {
      setState(() => _error = 'Google Sign-In failed');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SmartShift',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildTextField(_emailCtrl, 'Email', TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField(_passCtrl, 'Password', TextInputType.text, isObscure: true),
                  
                  if (_error.isNotEmpty) _buildErrorText(),
                  const SizedBox(height: 24),
                  
                  _buildLoginButton(),
                  const SizedBox(height: 12),
                  _buildGoogleButton(),
                  
                  const SizedBox(height: 24),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper UI Components ---

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType type, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _error,
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Login'),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _loginWithGoogle,
        icon: const Icon(Icons.login), 
        label: const Text('Sign in with Google'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: _loading
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              );
            },
      child: const Text("Don't have an account? Create one"),
    );
  }
}