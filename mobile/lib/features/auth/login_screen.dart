import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runAuthOp(Future<void> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Authentication failed');
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final controller = ref.read(authControllerProvider);
    await _runAuthOp(() => _registerMode
        ? controller.registerWithEmail(email, password)
        : controller.signInWithEmail(email, password));
  }

  Future<void> _signInWithGoogle() async {
    final controller = ref.read(authControllerProvider);
    await _runAuthOp(controller.signInWithGoogle);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cramly',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: c.accent,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      _registerMode ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    AppInput(
                      controller: _emailController,
                      placeholder: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.md),
                    AppInput(
                      controller: _passwordController,
                      placeholder: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _busy ? null : _submitEmail(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (_registerMode && v.length < 8) {
                          return 'Min 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Spacing.lg),
                    AppButton(
                      label: _registerMode ? 'Create account' : 'Sign in',
                      busy: _busy,
                      fullWidth: true,
                      size: AppButtonSize.lg,
                      onPressed: _busy ? null : _submitEmail,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(
                                  () => _registerMode = !_registerMode,
                                ),
                        child: Text(
                          _registerMode
                              ? 'Already have an account? Sign in'
                              : 'New here? Create an account',
                          style: TextStyle(color: c.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        Expanded(child: Divider(color: c.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                          ),
                          child: Text(
                            'or',
                            style: TextStyle(color: c.textMuted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: c.border)),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    AppButton(
                      label: 'Sign in with Google',
                      icon: Icons.account_circle_outlined,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.lg,
                      fullWidth: true,
                      onPressed: _busy ? null : _signInWithGoogle,
                    ),
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
