import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/country_code.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_phone_field.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  CountryCode _selectedCountry = CountryCode.defaultCountry;
  String _selectedRole = 'Buyer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = CountryCode.defaultCountry;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final country = _selectedCountry;
      final fullPhoneNumber =
          '${country.dialCode} ${_phoneController.text.trim()}';

      await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        phone: fullPhoneNumber,
        role: _selectedRole,
      );

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Account created successfully!');
        // Pop back to auth wrapper / root which automatically loads profile
        Navigator.popUntil(context, (route) => route.isFirst);
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
    _selectedCountry = _selectedCountry;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up to find and manage properties with ease',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.slateBlue,
                  ),
                ),
                const SizedBox(height: 28),

                // Full Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 18),

                // Phone with Country Code Dropdown & Dynamic Digit Validation
                CustomPhoneField(
                  controller: _phoneController,
                  initialCountry: _selectedCountry,
                  onCountryChanged: (country) {
                    setState(() => _selectedCountry = country);
                  },
                ),
                const SizedBox(height: 18),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Repeat your password',
                  prefixIcon: Icons.lock_clock_outlined,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Role Selection Header
                const Text(
                  'I want to join as',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 10),

                // Buyer vs Seller Cards Row
                Row(
                  children: [
                    // Buyer Card
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'Buyer'),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'Buyer'
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == 'Buyer'
                                  ? AppColors.primary
                                  : AppColors.borderGrey,
                              width: _selectedRole == 'Buyer' ? 2 : 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'Buyer'
                                          ? AppColors.primary
                                          : AppColors.scaffoldBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_search_rounded,
                                      size: 18,
                                      color: _selectedRole == 'Buyer'
                                          ? Colors.white
                                          : AppColors.slateBlue,
                                    ),
                                  ),
                                  if (_selectedRole == 'Buyer')
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Buyer',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Browse, compare & book visits',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slateBlue.withValues(alpha: 0.9),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Seller Card
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'Seller'),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'Seller'
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedRole == 'Seller'
                                  ? AppColors.primary
                                  : AppColors.borderGrey,
                              width: _selectedRole == 'Seller' ? 2 : 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'Seller'
                                          ? AppColors.primary
                                          : AppColors.scaffoldBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      size: 18,
                                      color: _selectedRole == 'Seller'
                                          ? Colors.white
                                          : AppColors.slateBlue,
                                    ),
                                  ),
                                  if (_selectedRole == 'Seller')
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Seller',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'List, edit & manage properties',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slateBlue.withValues(alpha: 0.9),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Sign Up Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleSignup,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.slateBlue,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
