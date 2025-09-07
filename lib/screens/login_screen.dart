import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/login_request.dart';
import '../services/auth_service.dart';
import '../services/exceptions.dart';
import '../widgets/background_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/login_form_card.dart';
import 'main_dashboard_screen.dart';

/// Login screen widget with form validation and authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = LoginRequest(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final result = await _authService.login(request);

      if (!mounted) return;

      if (result.success) {
        // Navigate directly to dashboard on successful login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
        );
      } else {
        _showErrorDialog(result.errorMessage ?? AppStrings.loginFailedMessage);
      }
    } on AuthenticationException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        _showErrorDialog(e.message);
      }
    } on AppException {
      if (mounted) {
        _showErrorDialog('Authentication failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.loginFailedTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(AppStrings.okButton),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(AppColors.infoBoxOpacity),
          ),
          child: const Icon(
            Icons.pets,
            size: AppConstants.iconSize,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.appTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.welcomeBack,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _usernameController,
            labelText: AppStrings.username,
            prefixIcon: Icons.person,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.usernameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _passwordController,
            labelText: AppStrings.password,
            prefixIcon: Icons.lock,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onEditingComplete: _handleLogin,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.passwordRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: AppStrings.loginButton,
            onPressed: _handleLogin,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        backgroundImageUrl: AppConstants.backgroundImageUrl,
        child: LoginFormCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppHeader(),
              const SizedBox(height: 40),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
