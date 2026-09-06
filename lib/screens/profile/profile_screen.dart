import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_snackbar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkNavy),
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: AppColors.slateBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slateBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
    }
  }

  Future<void> _handleResetPassword(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkNavy),
        ),
        content: Text(
          'We will send a password reset link to:\n$email\n\nDo you want to proceed?',
          style: const TextStyle(color: AppColors.slateBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slateBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Email', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authService.sendPasswordResetEmail(email);
        if (mounted) {
          CustomSnackBar.showSuccess(
            context,
            'Password reset link sent to your email!',
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.showError(context, AuthService.getErrorMessage(e));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userService.streamUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          final user = snapshot.data ??
              UserModel(
                uid: currentUser.uid,
                name: currentUser.displayName ?? 'Real Estate User',
                email: currentUser.email ?? '',
                phone: currentUser.phoneNumber ?? '',
                createdAt: DateTime.now(),
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Profile Header Card
                _buildHeaderCard(user),
                const SizedBox(height: 20),

                // Details Card
                _buildDetailsCard(user),
                const SizedBox(height: 20),

                // Account & Security Card
                _buildActionsCard(user),
                const SizedBox(height: 24),

                // Logout Button
                CustomButton(
                  text: 'Log Out',
                  icon: Icons.logout_rounded,
                  onPressed: _handleSignOut,
                  isOutlined: true,
                  backgroundColor: AppColors.error,
                  textColor: AppColors.error,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.name.isNotEmpty ? user.name : 'Real Estate User',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slateBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            value: user.phone.isNotEmpty ? user.phone : 'Not provided',
          ),
          const Divider(height: 24, color: AppColors.borderGrey),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Member Since',
            value:
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
          ),
          if (user.bio.isNotEmpty) ...[
            const Divider(height: 24, color: AppColors.borderGrey),
            _buildInfoRow(
              icon: Icons.info_outline_rounded,
              title: 'About / Bio',
              value: user.bio,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNavy),
            ),
            subtitle: const Text(
              'Update your name, phone, bio & role',
              style: TextStyle(fontSize: 12, color: AppColors.slateBlue),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.silverGrey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: user),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 64, color: AppColors.borderGrey),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.slateBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.slateBlue, size: 20),
            ),
            title: const Text(
              'Reset / Change Password',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNavy),
            ),
            subtitle: const Text(
              'Send password reset email to your address',
              style: TextStyle(fontSize: 12, color: AppColors.slateBlue),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.silverGrey),
            onTap: () => _handleResetPassword(user.email),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.slateBlue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.darkNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
