import 'package:flutter/material.dart';
import 'package:pigeon_track/constants/app_constants.dart';
import '../utils/responsive_utils.dart';

/// Dashboard screen showing live tournament data and statistics
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(AppConstants.backgroundImageUrl),
            fit: BoxFit.cover,
            opacity: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: ResponsiveUtils.getResponsivePadding(
                context,
                mobile: const EdgeInsets.all(16),
                tablet: const EdgeInsets.all(20),
                desktop: const EdgeInsets.all(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 28,
                        tablet: 32,
                        desktop: 36,
                        base: 32,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 4 : 8),
                  Text(
                    ResponsiveUtils.isMobile(context)
                        ? 'Pigeon Track - Tournament Management'
                        : 'Welcome to Pigeon Track - Live Tournament Management',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 14,
                        tablet: 16,
                        desktop: 16,
                        base: 16,
                      ),
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.isMobile(context) ? 16 : 32),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
