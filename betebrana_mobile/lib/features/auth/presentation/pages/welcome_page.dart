import 'package:flutter/material.dart';
import 'login_page.dart'; // Ensure correct path

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Custom colors derived from the design image
  static const Color primaryGreen = Color(0xFF39FF4C);
  static const Color darkBackground = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // 1. Background Image (Book/Library Placeholder)
          Positioned.fill(
            child: Image.asset(
              // Using a placeholder image for a book or library aesthetic
              'lib/features/auth/image/unnamed.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6), // Darken the image
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // 2. Gradient Overlay for better contrast
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    darkBackground.withOpacity(0.1),
                    darkBackground.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          // 3. Content Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(flex: 3),
                // Main Title
                const Text(
                  'Your Digital\nLibrary Awaits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                const Text(
                  'Access thousands of books, track your reading progress, and rent or queue titles instantly with BeteBrana.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const Spacer(flex: 1),
                // "Let's Go" Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 212, 108, 10),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text("Let's Go"),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}