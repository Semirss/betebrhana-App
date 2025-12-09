import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import '../../presentation/bloc/authentication_bloc.dart';
import '../../presentation/bloc/authentication_event.dart';
import '../../presentation/bloc/authentication_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Custom colors derived from the design image
  static const Color primaryGreen = Color.fromARGB(255, 230, 159, 7);
  static const Color darkBackground = Color(0xFF121212);
  static const Color inputFieldColor = Color(0xFF1E1E1E);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      // Removed AppBar for the full-screen immersive design
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 80, bottom: 24),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
              } else if (state is AuthAuthenticated) {
                // Assuming successful registration navigates back or to main screen
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Registration successful!')),
                  );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button to match the image style
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BeteBrana Logo/Icon placeholder
                    const Icon(Icons.menu_book_rounded, color: primaryGreen, size: 50),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    const Text(
                      'Create your account to access your full library.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Your Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Email or Phone',
                        hintText: 'Email or Phone',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password here',
                        suffixIcon: const Icon(Icons.remove_red_eye, color: Colors.white54),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field (kept as per original logic, updated style)
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Confirm password',
                        hintText: 'Confirm password',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: isLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Text('Sign up'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 'Or' Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white38)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Or', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ),
                        const Expanded(child: Divider(color: Colors.white38)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Social Login Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(
                          icon: FontAwesomeIcons.google,
                          onPressed: () {/* Google Register */},
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: FontAwesomeIcons.facebookF,
                          onPressed: () {/* Facebook Register */},
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: FontAwesomeIcons.apple,
                          onPressed: () {/* Apple Register */},
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: FontAwesomeIcons.instagram,
                          onPressed: () {/* Instagram Register */},
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText, String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: Colors.white54),
      hintStyle: const TextStyle(color: Colors.white30),
      suffixIcon: suffixIcon,
      fillColor: inputFieldColor,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

// Widget for the Social Login Buttons
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _RegisterPageState.inputFieldColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}