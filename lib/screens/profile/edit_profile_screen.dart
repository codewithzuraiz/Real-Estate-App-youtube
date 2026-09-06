import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/country_code.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_phone_field.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late String _selectedRole;
  late CountryCode _selectedCountry;

  final _userService = UserService();
  final _authService = AuthService();
  bool _isLoading = false;

  final List<String> _roles = [
    'Client / Buyer',
    'Property Investor',
    'Real Estate Agent',
    'Home Seller',
  ];

  @override
  void initState() {
    super.initState();
    final parsed = CountryCode.parsePhone(widget.user.phone);
    _selectedCountry = parsed.country;

    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(
      text: parsed.localNumber.replaceAll(RegExp(r'\D'), ''),
    );
    _bioController = TextEditingController(text: widget.user.bio);
    _selectedRole = _roles.contains(widget.user.role) ? widget.user.role : _roles.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fullPhoneNumber = _phoneController.text.trim().isNotEmpty
          ? '${_selectedCountry.dialCode} ${_phoneController.text.trim()}'
          : '';

      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        phone: fullPhoneNumber,
        bio: _bioController.text.trim(),
        role: _selectedRole,
      );

      await _userService.updateUser(updatedUser);
      await _authService.currentUser?.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Failed to update profile: $e');
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
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar preview
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            widget.user.name.isNotEmpty
                                ? widget.user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Phone with Country Code Dropdown & Dynamic Digit Validation
                CustomPhoneField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  initialCountry: _selectedCountry,
                  isRequired: false,
                  onCountryChanged: (country) {
                    setState(() => _selectedCountry = country);
                  },
                ),
                const SizedBox(height: 18),

                // Role Dropdown
                const Text(
                  'User Role',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: AppColors.slateBlue,
                      size: 20,
                    ),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                    }
                  },
                ),
                const SizedBox(height: 18),

                // Bio
                CustomTextField(
                  controller: _bioController,
                  label: 'About / Bio',
                  hint: 'Tell us a bit about yourself or property interests',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Save button
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _handleSave,
                  isLoading: _isLoading,
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
