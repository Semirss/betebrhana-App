import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import '../../presentation/bloc/authentication_bloc.dart';
import '../../presentation/bloc/authentication_event.dart';
import '../../presentation/bloc/authentication_state.dart';
import 'login_page.dart';

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

  String? _errorMessage;
  bool _isLoading = false;

  // Custom colors derived from the design image
  static const Color primaryGreen = Color.fromARGB(255, 230, 159, 7);
  static const Color darkBackground = Color(0xFF121212);
  static const Color inputFieldColor = Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    // This ensures we listen to the bloc even during rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authBloc = context.read<AuthBloc>();
      authBloc.stream.listen((state) {
        if (state is AuthFailure) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
          _showErrorSnackbar(state.message);
        } else if (state is AuthAuthenticated) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          _showSuccessAndNavigate();
        } else if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        }
      });
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessAndNavigate() {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration successful! Welcome to BeteBrana!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to login page after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Navigate to login page with a fresh context
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false, // Remove all previous routes
        );
      }
    });
  }

  void _clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    
    // Clear previous errors
    _clearError();
    
    // Close keyboard
    FocusScope.of(context).unfocus();
    
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _navigateToLogin() {
    if (_isLoading) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _navigateBack() {
    if (_isLoading) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 80, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button to match the image style
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: _isLoading ? null : _navigateBack,
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

              // Error message display
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                      onChanged: (_) => _clearError(),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Email',
                        hintText: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(
                            r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      onChanged: (_) => _clearError(),
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
                      onChanged: (_) => _clearError(),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Confirm password',
                        hintText: 'Confirm your password',
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
                      onChanged: (_) => _clearError(),
                    ),
                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      height: 56,
                      child: _isLoading
                          ? Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Creating your account...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : FilledButton(
                              onPressed: _onSubmit,
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
                              child: const Text('Sign up'),
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
                          onPressed: _isLoading ? null : () {/* Google Register */},
                          isLoading: _isLoading,
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: FontAwesomeIcons.facebookF,
                          onPressed: _isLoading ? null : () {/* Facebook Register */},
                          isLoading: _isLoading,
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: FontAwesomeIcons.apple,
                          onPressed: _isLoading ? null : () {/* Apple Register */},
                          isLoading: _isLoading,
                        ),
                        const SizedBox(width: 20),
                        _SocialButton(
                          icon: FontAwesomeIcons.instagram,
                          onPressed: _isLoading ? null : () {/* Instagram Register */},
                          isLoading: _isLoading,
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
                          onTap: _isLoading ? null : _navigateToLogin,
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: _isLoading ? Colors.white54 : primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
      errorStyle: const TextStyle(color: Colors.red),
    );
  }
}

// Widget for the Social Login Buttons
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SocialButton({
    required this.icon, 
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLoading ? 0.5 : 1.0,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _RegisterPageState.inputFieldColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLoading ? Colors.white30 : Colors.white54,
              width: 1,
            ),
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: isLoading ? Colors.white54 : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}