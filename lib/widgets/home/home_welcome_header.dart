import 'package:flutter/material.dart';

/// A header for the home page showing the Mayora logo and a welcome message.
class HomeWelcomeHeader extends StatelessWidget {
  const HomeWelcomeHeader({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF673AB7).withOpacity(0.1),
                const Color(0xFF9C27B0).withOpacity(0.1),
                const Color(0xFF00BCD4).withOpacity(0.1),
              ],
            ),
          ),
          child: Hero(
            tag: 'mayora_logo_home',
            child: Image.asset(
              'assets/images/mayora_logo.png',
              height: 120,
              width: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.flutter_dash, size: 120);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome $userName!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF673AB7),
          ),
        ),
      ],
    );
  }
}
