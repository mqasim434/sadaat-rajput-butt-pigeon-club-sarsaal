import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Background container widget with gradient and image overlay
class BackgroundContainer extends StatelessWidget {
  final Widget child;
  final String? backgroundImageUrl;
  final List<Color>? gradientColors;
  final double imageOpacity;

  const BackgroundContainer({
    super.key,
    required this.child,
    this.backgroundImageUrl,
    this.gradientColors,
    this.imageOpacity = AppColors.overlayOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? AppColors.backgroundGradient,
        ),
      ),
      child: backgroundImageUrl != null
          ? Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(backgroundImageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(imageOpacity),
                    BlendMode.overlay,
                  ),
                ),
              ),
              child: child,
            )
          : child,
    );
  }
}
