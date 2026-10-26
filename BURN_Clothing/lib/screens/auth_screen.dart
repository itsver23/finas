import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/ui_helpers.dart';

/// Email/password is required for a no-OTP Supabase signup. Phone is saved as
/// profile metadata, not used as a verified authentication identifier.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialScreen = 0});
  final int initialScreen;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late int _screen; // 0 login, 1 signup

  @override
  void initState() {
    super.initState();
    _screen = widget.initialScreen == 0 ? 0 : 1;
  }
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _accepted = false;

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _email, _password, _confirmPassword]) {
      c.dispose();
    }
    super.dispose();
  }

  void _change(int next) {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _screen = next;
      _form.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_screen == 1 && !_accepted) {
      notice(context, 'Please accept the Terms and Privacy Policy');
      return;
    }
    if (!connected) {
      notice(context, 'Configure SUPABASE_URL and SUPABASE_ANON_KEY first');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_screen == 1) {
        final response = await db.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {
            'first_name': _firstName.text.trim(),
            'last_name': _lastName.text.trim(),
            'phone': _phone.text.trim(),
          },
        );
        if (!mounted) return;
        if (response.user == null) {
          notice(context, 'Could not create the account');
          return;
        }
        // The desired flow ends on Log In, even if email confirmation is off.
        if (response.session != null) await db.auth.signOut();
        if (!mounted) return;
        _password.clear();
        _confirmPassword.clear();
        _change(0);
        notice(context, 'Account created. Log in to continue. If email confirmation is enabled, confirm your email first.');
      } else {
        final response = await db.auth.signInWithPassword(
          email: _email.text.trim(), password: _password.text);
        if (!mounted) return;
        if (response.session != null) {
          Navigator.of(context).pop(true);
        } else {
          notice(context, 'Unable to log in');
        }
      }
    } on AuthException catch (e) {
      if (mounted) notice(context, e.message);
    } catch (_) {
      if (mounted) notice(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      notice(context, 'Enter your email first');
      return;
    }
    if (!connected) {
      notice(context, 'Configure Supabase first');
      return;
    }
    try {
      await db.auth.resetPasswordForEmail(_email.text.trim());
      if (mounted) notice(context, 'Check your email for reset instructions');
    } catch (_) {
      if (mounted) notice(context, 'Unable to send reset email');
    }
  }

  Widget _field(String label, TextEditingController controller,
      {bool password = false, TextInputType? keyboard,
      List<TextInputFormatter>? formatters, bool confirmation = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        obscureText: password && !(confirmation ? _showConfirmPassword : _showPassword),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF191919),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF555555))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: red, width: 1.6)),
          suffixIcon: password ? IconButton(
            onPressed: () => setState(() {
              if (confirmation) {
                _showConfirmPassword = !_showConfirmPassword;
              } else {
                _showPassword = !_showPassword;
              }
            }),
            icon: Icon((confirmation ? _showConfirmPassword : _showPassword)
                ? Icons.visibility_off : Icons.visibility),
          ) : null,
        ),
        validator: (v) {
          final text = (v ?? '').trim();
          if (text.isEmpty) return '$label is required';
          if ((controller == _firstName || controller == _lastName) &&
              RegExp(r'[0-9]').hasMatch(text)) {
            return 'Numbers are not allowed in names';
          }
          if (controller == _phone && !RegExp(r'^09\d{9}$').hasMatch(text)) {
            return 'Use 11 digits starting with 09';
          }
          if (controller == _email &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
            return 'Enter a valid email address';
          }
          if (confirmation && (v ?? '') != _password.text) {
            return 'Passwords do not match';
          }
          if (controller == _password && text.length < 6) {
            return 'Use at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final login = _screen == 0;
    return Scaffold(
      backgroundColor: black,
      appBar: AppBar(
        backgroundColor: black,
        title: const Text('BURN CLOTHING'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _screen == 1 ? _change(0) : Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView(
                  key: ValueKey(_screen),
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                  children: [
                    Center(child: Icon(Icons.local_fire_department,
                      color: red, size: 48)),
                    const SizedBox(height: 12),
                    Center(child: Text(login ? 'Log In' : 'Sign Up',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800))),
                    const SizedBox(height: 10),
                    Center(child: Text(login ? 'Welcome back to BURN' :
                        'Create your BURN Clothing account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70))),
                    const SizedBox(height: 32),
                    if (!login) ...[
                      _field('First Name', _firstName,
                        keyboard: TextInputType.name,
                        formatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                        ]),
                      _field('Last Name', _lastName,
                        keyboard: TextInputType.name,
                        formatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                        ]),
                    ],
                    _field('Email Address', _email,
                      keyboard: TextInputType.emailAddress),
                    if (!login)
                      _field('Mobile Number (09XXXXXXXXX)', _phone,
                        keyboard: TextInputType.phone,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ]),
                    _field('Password', _password, password: true),
                    if (!login)
                      _field('Confirm Password', _confirmPassword,
                        password: true, confirmation: true),
                    if (login)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot your password?'),
                        ),
                      )
                    else
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _accepted,
                        activeColor: red,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'I accept the Terms & Conditions and Privacy Policy',
                          style: TextStyle(fontSize: 13),
                        ),
                        onChanged: (v) => setState(() => _accepted = v ?? false),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(height: 54, child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: red,
                        foregroundColor: Colors.white),
                      child: _busy ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white)) :
                        Text(login ? 'LOG IN' : 'CREATE ACCOUNT',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    const SizedBox(height: 28),
                    Center(child: TextButton(
                      onPressed: () => _change(login ? 1 : 0),
                      child: Text(login ? "Don't have an account? Sign Up" :
                        'Already have an account? Log In',
                        style: const TextStyle(color: Colors.white)),
                    )),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
