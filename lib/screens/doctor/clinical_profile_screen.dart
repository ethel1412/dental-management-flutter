import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ClinicalProfileScreen extends StatelessWidget {
  const ClinicalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Profiles'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information,
              size: 80,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Clinical Profiles',
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
