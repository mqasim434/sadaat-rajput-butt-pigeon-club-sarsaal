import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Card widget for the login form with consistent styling
class LoginFormCard extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const LoginFormCard({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppConstants.paddingLarge),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? AppConstants.maxLoginFormWidth,
            ),
            child: Card(
              elevation: AppConstants.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.cardBorderRadius,
                ),
              ),
              color: AppColors.cardBackground.withOpacity(
                AppColors.cardOpacity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingXLarge),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

