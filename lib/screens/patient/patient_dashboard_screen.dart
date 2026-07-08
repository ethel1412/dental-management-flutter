import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'xray_analysis_screen.dart';
import 'search_doctors_screen.dart';
import 'patient_profile_screen.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<AuthProvider>().userData;
    final name = userData?['name'] as String? ??
        userData?['full_name'] as String? ??
        'Patient';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PatientProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withBlue(180),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PatientProfileScreen()),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $name!',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'How are you feeling today?',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // AI X-ray CTA  —  the FEATURED action
              _buildXrayCta(context),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text('Quick Access',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),

              // Feature grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.search,
                    title: 'Find Doctors',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SearchDoctorsScreen()),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Appointments',
                    color: Colors.green,
                    onTap: () => _comingSoon(context, 'Appointments'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.medical_information,
                    title: 'Medical Records',
                    color: Colors.orange,
                    onTap: () => _comingSoon(context, 'Medical Records'),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.science,
                    title: 'Lab Orders',
                    color: Colors.purple,
                    onTap: () => _comingSoon(context, 'Lab Orders'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildXrayCta(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const XrayAnalysisScreen()),
      ),
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.biotech,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI X-ray Analysis',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upload your dental X-ray and get instant AI-powered analysis with per-tooth diagnosis.',
                      style:
                          TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
