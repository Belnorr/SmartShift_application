import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/sign_in_service.dart';
import 'register_page.dart';
import 'forgot_password_screen.dart';
import '../../services/remember_me_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // State
  bool _loading = false;
  String _error = '';

  // UI-only
  bool _rememberMe = false;

  // remember me
  List<SavedAccount> _saved = [];
  final FocusNode _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final list = await RememberMeStore.instance.load();
    if (!mounted) return;
    setState(() => _saved = list);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

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

      if (_rememberMe) {
        await RememberMeStore.instance.upsertEmail(email);
        await _loadSaved();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } catch (e) {
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await GoogleSignInService.instance.signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'Google Sign-In failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goRegister() {
    if (_loading) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _goForgot() {
    if (_loading) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgPath = "assets/auth_bg.png";


    const sheetRadius = 28.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // background
          Positioned.fill(
            child: Image.asset(bgPath, fit: BoxFit.cover),
          ),
          // dark tint
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha:0.45)),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Login to access your shifts and workforce dashboard.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom sheet
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.62,
                      widthFactor: 1,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(sheetRadius),
                            topRight: Radius.circular(sheetRadius),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AuthSegmentedTabs(
                                  leftLabel: "Login",
                                  rightLabel: "Register",
                                  leftSelected: true,
                                  onLeft: () {},
                                  onRight: _goRegister,
                                ),
                                const SizedBox(height: 14),
                                RawAutocomplete<SavedAccount>(
                                  textEditingController: _emailCtrl,
                                  focusNode: _emailFocus,
                                  optionsBuilder: (TextEditingValue v) {
                                    final q = v.text.trim().toLowerCase();
                                    if (q.isEmpty)
                                      return _saved; // show all saved
                                    return _saved.where((s) =>
                                        s.email.toLowerCase().contains(q));
                                  },
                                  displayStringForOption: (s) => s.email,
                                  onSelected: (s) {
                                    _emailCtrl.text = s.email;
                                    _passCtrl
                                        .clear(); // don't autofill password
                                  },
                                  fieldViewBuilder: (context, textCtrl,
                                      focusNode, onFieldSubmitted) {
                                    return _CapsuleField(
                                      controller: textCtrl,
                                      focusNode: focusNode,
                                      hint: "E-mail ID",
                                      icon: Icons.mail_outline,
                                      keyboardType: TextInputType.emailAddress,
                                      enabled: !_loading,
                                    );
                                  },
                                  optionsViewBuilder:
                                      (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 6,
                                        borderRadius: BorderRadius.circular(14),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxHeight: 220, maxWidth: 520),
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            itemCount: options.length,
                                            itemBuilder: (_, i) {
                                              final opt = options.elementAt(i);
                                              return ListTile(
                                                dense: true,
                                                title: Text(opt.email,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                onTap: () => onSelected(opt),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _CapsuleField(
                                  controller: _passCtrl,
                                  hint: "Password",
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
                                          : (v) =>
                                              setState(() => _rememberMe = v),
                                      label: "Remember me",
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _loading ? null : _goForgot,
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_error.isNotEmpty) ...[
                                  const SizedBox(height: 6),
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
                                  label: "Login",
                                  loading: _loading,
                                  onPressed: _login,
                                ),
                                const SizedBox(height: 12),
                                const _DividerOr(),
                                const SizedBox(height: 12),
                                _GoogleButton(
                                  loading: _loading,
                                  onPressed: _loginWithGoogle,
                                  label: "Google",
                                ),
                              ],
                            ),
                          ),
                        ),
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
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool enabled;

  const _CapsuleField({
    required this.controller,
    this.focusNode,
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
              focusNode: focusNode,
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
  const _DividerOr();

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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
