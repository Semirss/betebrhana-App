import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../presentation/bloc/authentication_bloc.dart';
import '../../presentation/bloc/authentication_event.dart';
import '../../presentation/bloc/authentication_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Theme Colors
  static const Color _backgroundColor = AppColors.lightBackground;
  static const Color _surfaceColor = AppColors.lightCard;
  static const Color _accentColor = AppColors.purple;
  static const Color _textPrimary = AppColors.lightText;
  static const Color _textSecondary = AppColors.lightSubtext;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          setState(() {
            _errorMessage = state.message.replaceAll('Exception: ', '');
          });
        } else if (state is AuthAuthenticated) {
           setState(() {
            _errorMessage = null;
          });
          // Navigation is handled by the parent _AppWrapper
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),

                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/icon/betebranalogo2_upscaled.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Title
                        const Text(
                          'Betebrana',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Subtitle Badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.library_music_rounded, color: Color(0xFF1E1E1E), size: 14),
                            SizedBox(width: 8),
                            Text(
                              ' Book Library',
                              style: TextStyle(
                                color: Color(0xFF1E1E1E),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // --- Error Display ---
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red[800], fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // --- Email Input ---
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email is required';
                            if (!value.contains('@')) return 'Invalid email address';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // --- Password Input ---
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // --- Login Button ---
                        if (isLoading)
                          const Center(
                            child: CircularProgressIndicator(color: Color(0xFFFF7A3B)),
                          )
                        else
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9A5E), Color(0xFFFF7A3B)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7A3B).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                splashColor: Colors.white.withOpacity(0.2),
                                highlightColor: Colors.white.withOpacity(0.1),
                                onTap: _onSubmit,
                                child: const Center(
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Forgot Password Link
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black45,
                          ),
                          child: const Text(
                            'Forgot Password',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // --- Footer ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account yet? ",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToRegister,
                              child: const Text(
                                "Signup Now",
                                style: TextStyle(
                                  color: Color(0xFFFF7A3B),
                                  fontSize: 14,
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
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
      cursorColor: const Color(0xFFFF7A3B),
      validator: validator,
      onChanged: (_) {
        if (_errorMessage != null) {
          setState(() {
            _errorMessage = null;
          });
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 15, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFFF7A3B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }
}