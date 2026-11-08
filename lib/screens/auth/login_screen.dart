import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isSendingReset = false;

  static const String _backgroundImage = 'assets/images/login_bg.jpg';

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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

    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }

    if (message.contains('too many requests')) {
      return 'Too many attempts. Please wait and try again.';
    }

    if (message.contains('email address not authorized')) {
      return 'Email delivery is not enabled for this address yet. '
          'Please check the Supabase email configuration.';
    }

    return error.message;
  }

  // REAL SUPABASE LOGIN
  Future<void> login() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.signInWithEmail(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        _showMessage(
          'Login did not create a session. Please verify your email '
          'and try again.',
        );
        return;
      }

      _showMessage('Welcome back to VoyageMate!');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error, stackTrace) {
      debugPrint('VoyageMate login error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Unable to log in. Check your internet connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // FORGOT PASSWORD
  Future<void> _sendPasswordReset() async {
    if (_isSendingReset) return;

    final email = emailController.text.trim().toLowerCase();

    if (!_isValidEmail(email)) {
      _showMessage('Enter a valid email address first.');
      return;
    }

    setState(() {
      _isSendingReset = true;
    });

    try {
      await _authService.sendPasswordResetEmail(email);

      _showMessage(
        'Password recovery request submitted. Check your email inbox.',
      );
    } on AuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error) {
      debugPrint('Password reset error: $error');

      _showMessage('Unable to send the recovery email. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReset = false;
        });
      }
    }
  }

  Widget _buildBackgroundFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173B66), Color(0xFF286A91), Color(0xFF10243C)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('VoyageMate background image failed to load: $error');

              return _buildBackgroundFallback();
            },
          ),

          Container(color: Colors.black.withValues(alpha: 0.45)),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flight_takeoff,
                          size: 80,
                          color: Colors.white,
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'VoyageMate',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Explore Smarter • Travel Better',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 40),

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
                              return 'Enter a valid email';
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
                              return 'Please enter your password';
                            }

                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        CustomButton(
                          text: _isLoading ? 'Signing in...' : 'Login',
                          onPressed: login,
                        ),

                        if (_isLoading) ...[
                          const SizedBox(height: 12),
                          const CircularProgressIndicator(color: Colors.white),
                        ],

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: _isSendingReset
                              ? null
                              : _sendPasswordReset,
                          child: Text(
                            _isSendingReset
                                ? 'Sending recovery email...'
                                : 'Forgot Password?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            minimumSize: const Size(double.infinity, 55),
                          ),
                          onPressed: () {
                            _showMessage(
                              'Google Sign-In will be configured separately.',
                            );
                          },
                          icon: const Icon(Icons.g_mobiledata, size: 35),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New here?',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
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
        ],
      ),
    );
  }
}
