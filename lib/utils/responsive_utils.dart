import 'package:flutter/material.dart';

/// Utility class for responsive design and screen size management
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  /// Get screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return ScreenType.mobile;
    if (width < tabletBreakpoint) return ScreenType.tablet;
    if (width < desktopBreakpoint) return ScreenType.desktop;
    return ScreenType.largeDesktop;
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get number of columns for grid based on screen size
  static int getGridColumns(
    BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
    int largeDesktopColumns = 4,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobileColumns;
      case ScreenType.tablet:
        return tabletColumns;
      case ScreenType.desktop:
        return desktopColumns;
      case ScreenType.largeDesktop:
        return largeDesktopColumns;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (isMobile(context)) {
      return mobile ?? const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return tablet ?? const EdgeInsets.all(20);
    } else {
      return desktop ?? const EdgeInsets.all(24);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    required double base,
  }) {
    if (isMobile(context)) {
      return mobile ?? base * 0.9;
    } else if (isTablet(context)) {
      return tablet ?? base;
    } else {
      return desktop ?? base * 1.1;
    }
  }

  /// Get responsive width (useful for dialogs and containers)
  static double getResponsiveWidth(
    BuildContext context, {
    double mobileRatio = 0.9,
    double tabletRatio = 0.7,
    double desktopRatio = 0.5,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * mobileRatio;
    } else if (isTablet(context)) {
      return screenWidth * tabletRatio;
    } else {
      return screenWidth * desktopRatio;
    }
  }

  /// Get responsive height (useful for dialogs and containers)
  static double getResponsiveHeight(
    BuildContext context, {
    double mobileRatio = 0.8,
    double tabletRatio = 0.7,
    double desktopRatio = 0.6,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (isMobile(context)) {
      return screenHeight * mobileRatio;
    } else if (isTablet(context)) {
      return screenHeight * tabletRatio;
    } else {
      return screenHeight * desktopRatio;
    }
  }

  /// Get sidebar width based on screen size and collapsed state
  static double getSidebarWidth(BuildContext context, bool isCollapsed) {
    if (isCollapsed) return 80;

    if (isMobile(context)) return 280; // Full width on mobile (drawer)
    if (isTablet(context)) return 240;
    return 280; // Desktop
  }

  /// Determine if sidebar should be a drawer on mobile
  static bool shouldUseDrawer(BuildContext context) {
    return isMobile(context);
  }

  /// Get responsive card elevation
  static double getCardElevation(BuildContext context) {
    return isMobile(context) ? 2 : 4;
  }

  /// Get responsive border radius
  static BorderRadius getResponsiveBorderRadius(BuildContext context) {
    final radius = isMobile(context) ? 8.0 : 12.0;
    return BorderRadius.circular(radius);
  }
}

/// Enum for different screen types
enum ScreenType { mobile, tablet, desktop, largeDesktop }

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);
    return builder(context, screenType);
  }
}

/// Responsive layout widget for different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < ResponsiveUtils.mobileBreakpoint) {
          return mobile;
        } else if (constraints.maxWidth < ResponsiveUtils.desktopBreakpoint) {
          return tablet ?? mobile;
        } else {
          return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}
