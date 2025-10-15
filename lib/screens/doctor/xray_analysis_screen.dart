import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class XrayAnalysisScreen extends StatelessWidget {
  const XrayAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('X-ray Analysis'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'X-ray Analysis',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}
