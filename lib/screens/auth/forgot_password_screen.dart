import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(_emailController.text);
      if (mounted) {
        setState(() {
          _emailSent = true;
        });
        CustomSnackBar.showSuccess(
          context,
          'Password reset link sent! Check your inbox.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, AuthService.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Titles
          const Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your registered email address below and we will send you instructions to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.slateBlue,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your registered email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Submit Button
          CustomButton(
            text: 'Send Reset Link',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),

          // Back to Login Link
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.slateBlue),
                  SizedBox(width: 6),
                  Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: AppColors.slateBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 46,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email Sent!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We have sent password recovery instructions to:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.slateBlue,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),
        CustomButton(
          text: 'Return to Sign In',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() => _emailSent = false);
              _handleResetPassword();
            },
            child: const Text(
              "Didn't receive email? Resend",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
