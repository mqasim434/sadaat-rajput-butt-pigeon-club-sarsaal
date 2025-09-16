import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.3),
              AppColors.primary.withOpacity(0.1),
              Colors.white.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Full-width pigeon background image
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.primary.withOpacity(0.1),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
              ),
              child: Image.network(
                'https://www.aljazeera.com/wp-content/uploads/2022/07/AP22178310836751.jpg?resize=1170%2C780&quality=80',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a different pigeon image
                  return Image.network(
                    'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // If both images fail, show gradient background
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.1),
                              Colors.white.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.pets,
                            size: 100,
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo/Title
                          Icon(
                            Icons.emoji_events,
                            size: MediaQuery.of(context).size.width < 600
                                ? 56
                                : 64,
                            color: AppColors.primary,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width < 600
                                ? 12
                                : 16,
                          ),
                          Text(
                            AppStrings.appTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 24
                                  : 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width < 600
                                ? 6
                                : 8,
                          ),
                          Text(
                            'Dashboard',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 16
                                  : 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width < 600
                                ? 24
                                : 32,
                          ),
                          // Welcome message
                          Text(
                            'Welcome to your dashboard!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 18
                                  : 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width < 600
                                ? 12
                                : 16,
                          ),
                          Text(
                            'Manage tournaments, track pigeon flights, and view live results',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600
                                  ? 14
                                  : 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width < 600
                                ? 32
                                : 40,
                          ),
                          // Quick stats or features
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFeatureCard(
                                icon: Icons.emoji_events,
                                title: 'Tournaments',
                                subtitle: 'Manage events',
                                context: context,
                              ),
                              _buildFeatureCard(
                                icon: Icons.analytics,
                                title: 'Results',
                                subtitle: 'View scores',
                                context: context,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
