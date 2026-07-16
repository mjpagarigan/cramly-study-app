import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_input.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/learning_trace.dart';

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

  Future<bool> _runAuthOp(Future<void> Function() op) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await op();
      return true;
    } on FirebaseAuthException catch (error) {
      _showError(_messageFor(error));
      return false;
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_canceled' || error.code == 'canceled') {
        _showMessage('Google sign-in was cancelled.');
      } else {
        _showError(
          'We could not connect to Cramly. Check your connection and try again.',
        );
      }
      return false;
    } catch (_) {
      _showError(
        'We could not connect to Cramly. Check your connection and try again.',
      );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final controller = ref.read(authControllerProvider);
    await _runAuthOp(
      () => _registerMode
          ? controller.registerWithEmail(email, password)
          : controller.signInWithEmail(email, password),
    );
  }

  Future<void> _signInWithGoogle() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final completed = await _runAuthOp(
      ref.read(authControllerProvider).signInWithGoogle,
    );
    if (completed && mounted && FirebaseAuth.instance.currentUser == null) {
      _showMessage('Google sign-in was cancelled.');
    }
  }

  void _showError(String message) => _showMessage(message);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleMode() {
    if (_busy) return;
    setState(() => _registerMode = !_registerMode);
    _formKey.currentState?.reset();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(email)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required.';
    if (_registerMode && password.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  static String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'That email or password does not match our records.',
      'email-already-in-use' => 'An account already uses that email address.',
      'weak-password' => 'Use a stronger password with at least 8 characters.',
      'too-many-requests' =>
        'Too many attempts. Wait a moment before trying again.',
      'network-request-failed' =>
        'We could not connect. Check your connection and try again.',
      'account-exists-with-different-credential' =>
        'That email uses a different sign-in method.',
      _ =>
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Authentication failed. Try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              Spacing.page,
              Spacing.xl,
              Spacing.page,
              Spacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BrandMark(),
                      ),
                      const SizedBox(height: 28),
                      const LearningTrace(width: 152),
                      const SizedBox(height: Spacing.lg),
                      AnimatedSwitcher(
                        duration: context.reduceMotion
                            ? Duration.zero
                            : AppDurations.card,
                        child: Column(
                          key: ValueKey(_registerMode),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 245),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  _registerMode
                                      ? 'Start your learning trace.'
                                      : 'Make sense of what you study.',
                                  style: AppTheme.display(
                                    context,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w600,
                                    height: 0.98,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _registerMode
                                  ? 'Create an account with your email and password.'
                                  : 'Sign in to continue your learning trace.',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppInput(
                        controller: _emailController,
                        label: 'Email',
                        placeholder: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: Spacing.md),
                      AppInput(
                        controller: _passwordController,
                        label: 'Password',
                        placeholder: _registerMode
                            ? 'At least 8 characters'
                            : 'Your password',
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: [
                          _registerMode
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_busy) _submitEmail();
                        },
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: Spacing.lg),
                      AppButton(
                        label: _registerMode ? 'Create account' : 'Sign in',
                        busy: _busy,
                        fullWidth: true,
                        size: AppButtonSize.md,
                        onPressed: _busy ? null : _submitEmail,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.lg,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: c.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md,
                              ),
                              child: Text(
                                'or',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: c.muted),
                              ),
                            ),
                            Expanded(child: Divider(color: c.border)),
                          ],
                        ),
                      ),
                      AppButton(
                        label: 'Continue with Google',
                        variant: AppButtonVariant.secondary,
                        fullWidth: true,
                        busy: _busy,
                        onPressed: _busy ? null : _signInWithGoogle,
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _registerMode
                                  ? 'Already have an account?'
                                  : 'New to Cramly?',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: c.muted),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _toggleMode,
                            child: Text(
                              _registerMode ? 'Sign in' : 'Create an account',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
