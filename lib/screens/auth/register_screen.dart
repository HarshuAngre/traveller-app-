import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('user already registered')) {
      return 'An account with this email may already exist. '
          'Try logging in instead.';
    }

    if (message.contains('password should be')) {
      return 'Your password does not meet the security requirements.';
    }

    if (message.contains('email address not authorized')) {
      return 'Supabase email delivery is not enabled for this address yet.';
    }

    if (message.contains('too many requests')) {
      return 'Too many registration attempts. Please wait and try again.';
    }

    return error.message;
  }

  Future<void> _register() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.registerWithEmail(
        fullName: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
      );

      if (!mounted) return;

      // Supabase may require email verification before login.
      if (response.session == null) {
        await _showEmailVerificationDialog();

        if (!mounted) return;

        // Return to login after the user acknowledges the message.
        Navigator.of(context).pop();
        return;
      }

      // If email confirmation is disabled, signup may create
      // an authenticated session immediately.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error, stackTrace) {
      debugPrint('VoyageMate registration error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Unable to create your account. Check your internet connection '
        'and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEmailVerificationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.mark_email_read_outlined,
            size: 45,
            color: Color(0xFF1565C0),
          ),
          title: const Text('Check your email'),
          content: Text(
            'Your registration request was submitted for '
            '${emailController.text.trim()}.\n\n'
            'Check your inbox for a confirmation email. '
            'After confirming your email, return to VoyageMate '
            'and log in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continue to Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFF1565C0),
                    child: Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Join VoyageMate',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Create an account to start your travel journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  CustomTextField(
                    hint: 'Full Name',
                    icon: Icons.person,
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }

                      if (value.trim().length < 2) {
                        return 'Enter a valid name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    hint: 'Email',
                    icon: Icons.email,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      if (!_isValidEmail(value)) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    hint: 'Password',
                    icon: Icons.lock,
                    obscureText: true,
                    controller: passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please create a password';
                      }

                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    controller: confirmPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  CustomButton(
                    text: _isLoading ? 'Creating Account...' : 'Create Account',
                    onPressed: _register,
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(color: Color(0xFF1565C0)),
                  ],

                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Login',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
