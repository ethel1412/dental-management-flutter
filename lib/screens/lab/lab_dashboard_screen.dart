import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'orders_screen.dart';
import 'lab_profile_screen.dart';
import 'lab_reports_screen.dart';
import 'lab_services_screen.dart';

class LabDashboardScreen extends StatelessWidget {
  const LabDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<AuthProvider>().userData;
    final name = userData?['name'] as String? ??
        userData?['lab_name'] as String? ??
        'Lab';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Lab Dashboard'),
        backgroundColor: AppConstants.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const LabProfileScreen()),
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
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.accentColor,
                        AppConstants.accentColor.withGreen(120),
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
                              builder: (_) => const LabProfileScreen()),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'L',
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
                              'Welcome, $name!',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage your orders and services',
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
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text('Quick Access',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.shopping_bag,
                    title: 'All Orders',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const OrdersScreen(initialFilter: 'all')),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.pending_actions,
                    title: 'Pending',
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const OrdersScreen(initialFilter: 'pending')),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.check_circle,
                    title: 'Completed',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrdersScreen(
                              initialFilter: 'completed')),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Reports',
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LabReportsScreen()),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.settings,
                    title: 'Services',
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LabServicesScreen()),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.person,
                    title: 'My Profile',
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LabProfileScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
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
