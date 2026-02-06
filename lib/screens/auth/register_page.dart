import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/sign_in_service.dart';
import 'login_page.dart';
import '../../services/remember_me_store.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _role = 'worker';
  bool _loading = false;
  String _error = '';

  // UI-only
  bool _rememberMe = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    if (_confirmCtrl.text != password) {
      setState(() => _error = 'Passwords do not match');
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

      debugPrint("AUTH OK uid=${cred.user!.uid}");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
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
      if (_rememberMe) {
        await RememberMeStore.instance.upsertEmail(email);
      }

      debugPrint("FIRESTORE OK wrote users/${cred.user!.uid}");
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Registration failed');
    } on FirebaseException catch (e) {
      setState(() => _error = "Firestore failed: ${e.code} - ${e.message}");
    } catch (e) {
      setState(() => _error = "Unknown error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await GoogleSignInService.instance.signInWithGoogle(role: _role);
    } catch (e) {
      setState(() => _error = 'Google registration failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goLogin() {
    if (_loading) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgPath = "assets/img/auth_bg.png";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(bgPath, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha:0.45)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Create Your\nFree Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Sign up to start booking and managing shifts smarter.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AuthSegmentedTabs(
                            leftLabel: "Login",
                            rightLabel: "Register",
                            leftSelected: false,
                            onLeft: _goLogin,
                            onRight: () {},
                          ),
                          const SizedBox(height: 14),
                          _CapsuleField(
                            controller: _nameCtrl,
                            hint: "Name",
                            icon: Icons.person_outline,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 12),
                          _CapsuleField(
                            controller: _emailCtrl,
                            hint: "E-mail ID",
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 12),
                          _CapsuleField(
                            controller: _passCtrl,
                            hint: "Password",
                            icon: Icons.lock_outline,
                            obscure: true,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 12),
                          _CapsuleField(
                            controller: _confirmCtrl,
                            hint: "Confirm Password",
                            icon: Icons.lock_outline,
                            obscure: true,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _TinyCheck(
                                value: _rememberMe,
                                onChanged: _loading
                                    ? null
                                    : (v) => setState(() => _rememberMe = v),
                                label: "Remember me",
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _loading ? null : _goLogin,
                                child: const Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.business_center_outlined,
                                    size: 18, color: Color(0xFF6B7280)),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Register as Employer",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Switch(
                                  value: _role == 'employer',
                                  onChanged: _loading
                                      ? null
                                      : (v) => setState(() =>
                                          _role = v ? 'employer' : 'worker'),
                                ),
                              ],
                            ),
                          ),
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _PrimaryButton(
                            label: "Create Account",
                            loading: _loading,
                            onPressed: _register,
                          ),
                          const SizedBox(height: 12),
                          _DividerOr(),
                          const SizedBox(height: 12),
                          _GoogleButton(
                            loading: _loading,
                            onPressed: _registerWithGoogle,
                            label: "Google",
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- UI pieces ----------

class _AuthSegmentedTabs extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _AuthSegmentedTabs({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    final selected = leftSelected ? 0 : 1;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegTab(
              label: leftLabel,
              selected: selected == 0,
              onTap: onLeft,
            ),
          ),
          Expanded(
            child: _SegTab(
              label: rightLabel,
              selected: selected == 1,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color:
                  selected ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsuleField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool enabled;

  const _CapsuleField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              enabled: enabled,
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  const _TinyCheck({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _DividerOr extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "or",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(child: Divider(height: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final String label;

  const _GoogleButton({
    required this.loading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, size: 28),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
