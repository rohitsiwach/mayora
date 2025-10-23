import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Mayora'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Hero(
              tag: 'mayora_logo_about',
              child: Container(
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
                child: Image.asset(
                  'assets/images/mayora_logo_large.png',
                  height: 200,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.flutter_dash,
                      size: 200,
                      color: Color(0xFF673AB7),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Mayora',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF673AB7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cross-Platform Excellence',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildFeatureItem(
                      Icons.smartphone,
                      'Android Support',
                      'Native Android experience with material design',
                    ),
                    _buildFeatureItem(
                      Icons.phone_iphone,
                      'iOS Support',
                      'Seamless iOS integration with Cupertino design',
                    ),
                    _buildFeatureItem(
                      Icons.web,
                      'Web Support',
                      'Responsive web application for all browsers',
                    ),
                    _buildFeatureItem(
                      Icons.palette,
                      'Beautiful Design',
                      'Modern UI with gradient themes and animations',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technology Stack',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTechItem('Flutter', '3.35.4'),
                    _buildTechItem('Dart', '3.9.2'),
                    _buildTechItem('Material Design', '3.0'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '© 2025 Mayora. All rights reserved.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF673AB7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF673AB7), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(String name, String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            version,
            style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
