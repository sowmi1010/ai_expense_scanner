import 'package:flutter/material.dart';

import '../../core/ui/app_spacing.dart';
import '../../core/ui/glass.dart';
import '../../data/services/auth_local_service.dart';

class AuthScreen extends StatefulWidget {
  final AuthLocalService authService;
  final ValueChanged<String> onSignedIn;

  const AuthScreen({
    super.key,
    required this.authService,
    required this.onSignedIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _isSignInMode = true;
  bool _isSigningIn = false;
  bool _isSigningUp = false;
  String? _signInError;
  String? _signUpError;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() {
      _signInError = null;
      _isSigningIn = true;
    });

    SignInResult result;
    try {
      result = await widget.authService.signIn(
        email: _signInEmailController.text,
        password: _signInPasswordController.text,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSigningIn = false;
        _signInError = 'Sign in failed. Please try again.';
      });
      return;
    }

    if (!mounted) return;

    setState(() => _isSigningIn = false);

    if (!result.isSuccess) {
      setState(() => _signInError = result.errorMessage);
      return;
    }

    widget.onSignedIn(result.user!.name);
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    final password = _signUpPasswordController.text;
    final confirmPassword = _signUpConfirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _signUpError = 'Password and confirm password must match.';
      });
      return;
    }

    setState(() {
      _signUpError = null;
      _isSigningUp = true;
    });

    try {
      await widget.authService.register(
        name: _signUpNameController.text,
        email: _signUpEmailController.text,
        password: _signUpPasswordController.text,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSigningUp = false;
        _signUpError = 'Registration failed. Please try again.';
      });
      return;
    }

    if (!mounted) return;

    _signInEmailController.text = _signUpEmailController.text.trim();
    _signInPasswordController.clear();
    _signUpPasswordController.clear();
    _signUpConfirmPasswordController.clear();

    setState(() {
      _isSignInMode = true;
      _isSigningUp = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful. Please sign in.')),
    );
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(text)) return 'Enter a valid email.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.surface.withValues(alpha: 0.96),
                  cs.surfaceContainerHighest.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Glass(
                    emphasize: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Expense Scanner',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create your account and log in to continue.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeButton(
                                title: 'Sign In',
                                selected: _isSignInMode,
                                onTap: () {
                                  setState(() => _isSignInMode = true);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ModeButton(
                                title: 'Sign Up',
                                selected: !_isSignInMode,
                                onTap: () {
                                  setState(() => _isSignInMode = false);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _isSignInMode
                              ? _SignInForm(
                                  key: const ValueKey('signin'),
                                  formKey: _signInFormKey,
                                  emailController: _signInEmailController,
                                  passwordController: _signInPasswordController,
                                  errorMessage: _signInError,
                                  isBusy: _isSigningIn,
                                  emailValidator: _validateEmail,
                                  passwordValidator: _validatePassword,
                                  onSubmit: _handleSignIn,
                                )
                              : _SignUpForm(
                                  key: const ValueKey('signup'),
                                  formKey: _signUpFormKey,
                                  nameController: _signUpNameController,
                                  emailController: _signUpEmailController,
                                  passwordController: _signUpPasswordController,
                                  confirmPasswordController:
                                      _signUpConfirmPasswordController,
                                  errorMessage: _signUpError,
                                  isBusy: _isSigningUp,
                                  requiredValidator: _validateRequired,
                                  emailValidator: _validateEmail,
                                  passwordValidator: _validatePassword,
                                  onSubmit: _handleSignUp,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected
              ? cs.primary.withValues(alpha: 0.16)
              : cs.surface.withValues(alpha: 0.40),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.50)
                : cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? errorMessage;
  final bool isBusy;
  final String? Function(String?) emailValidator;
  final String? Function(String?) passwordValidator;
  final VoidCallback onSubmit;

  const _SignInForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.errorMessage,
    required this.isBusy,
    required this.emailValidator,
    required this.passwordValidator,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: emailController,
            validator: emailValidator,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: passwordController,
            validator: passwordValidator,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : onSubmit,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? errorMessage;
  final bool isBusy;
  final String? Function(String?, String) requiredValidator;
  final String? Function(String?) emailValidator;
  final String? Function(String?) passwordValidator;
  final VoidCallback onSubmit;

  const _SignUpForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.errorMessage,
    required this.isBusy,
    required this.requiredValidator,
    required this.emailValidator,
    required this.passwordValidator,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            validator: (value) => requiredValidator(value, 'Name'),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: emailController,
            validator: emailValidator,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: passwordController,
            validator: passwordValidator,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: confirmPasswordController,
            validator: passwordValidator,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_person_outlined),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : onSubmit,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
          ),
        ],
      ),
    );
  }
}
