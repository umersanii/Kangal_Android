import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kangal/data/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';

class SupabaseAuthScreen extends StatefulWidget {
  const SupabaseAuthScreen({super.key});

  @override
  State<SupabaseAuthScreen> createState() => _SupabaseAuthScreenState();
}

class _SupabaseAuthScreenState extends State<SupabaseAuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _signUpFormKey = GlobalKey<FormState>();
  final _signInFormKey = GlobalKey<FormState>();

  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) {
      return;
    }

    final authService = context.read<SupabaseAuthService>();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await authService.signUp(
        _signUpEmailController.text.trim(),
        _signUpPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign-up successful')));
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Sign-up failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) {
      return;
    }

    final authService = context.read<SupabaseAuthService>();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await authService.signIn(
        _signInEmailController.text.trim(),
        _signInPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sign-in successful')));
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Sign-in failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Authentication'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sign Up'),
            Tab(text: 'Sign In'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AuthForm(
                  formKey: _signUpFormKey,
                  emailController: _signUpEmailController,
                  passwordController: _signUpPasswordController,
                  confirmPasswordController: _signUpConfirmPasswordController,
                  isSubmitting: _isSubmitting,
                  submitLabel: 'Sign Up',
                  validateEmail: _validateEmail,
                  validatePassword: _validatePassword,
                  onSubmit: _handleSignUp,
                  showConfirmPassword: true,
                ),
                _AuthForm(
                  formKey: _signInFormKey,
                  emailController: _signInEmailController,
                  passwordController: _signInPasswordController,
                  isSubmitting: _isSubmitting,
                  submitLabel: 'Sign In',
                  validateEmail: _validateEmail,
                  validatePassword: _validatePassword,
                  onSubmit: _handleSignIn,
                  showConfirmPassword: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.submitLabel,
    required this.validateEmail,
    required this.validatePassword,
    required this.onSubmit,
    required this.showConfirmPassword,
    this.confirmPasswordController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? confirmPasswordController;
  final bool isSubmitting;
  final String submitLabel;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final Future<void> Function() onSubmit;
  final bool showConfirmPassword;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              textInputAction: showConfirmPassword
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: validatePassword,
            ),
            if (showConfirmPassword) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                validator: (value) {
                  final baseValidation = validatePassword(value);
                  if (baseValidation != null) {
                    return baseValidation;
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
