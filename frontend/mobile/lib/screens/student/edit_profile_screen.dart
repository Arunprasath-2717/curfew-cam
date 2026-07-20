import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/avatar_widget.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  File? _pickedImage;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final res = await AuthService.getMe();
    if (mounted && res['success'] == true && res['data'] != null) {
      final d = res['data'];
      setState(() {
        _firstNameCtrl.text = d['first_name'] ?? '';
        _lastNameCtrl.text = d['last_name'] ?? '';
        _phoneCtrl.text = d['phone_number'] ?? '';
        _currentAvatarUrl = d['avatar'] as String?;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    // Upload avatar first if one was picked
    if (_pickedImage != null) {
      final avatarRes = await AuthService.uploadAvatar(_pickedImage!);
      if (!mounted) return;
      if (avatarRes['success'] != true) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(avatarRes['message'] ?? 'Photo upload failed'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    final res = await AuthService.updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Edit Profile', showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar picker ──
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _pickedImage != null
                              ? CircleAvatar(
                                  radius: 52,
                                  backgroundImage: FileImage(_pickedImage!),
                                )
                              : AvatarWidget(
                                  avatarUrl: _currentAvatarUrl,
                                  initials: _firstNameCtrl.text.isEmpty ? 'U' : _firstNameCtrl.text,
                                  radius: 52,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  textColor: Theme.of(context).scaffoldBackgroundColor,
                                ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, size: 16, color: Theme.of(context).scaffoldBackgroundColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Tap to change photo', style: AppTextStyles.bodySecondary),
                  ),
                  const SizedBox(height: 28),
                  _buildField('First Name', _firstNameCtrl, Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildField('Last Name', _lastNameCtrl, Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: AppColors.gradientNavy),
                      boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saving ? null : _save,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _saving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Save Changes', style: AppTextStyles.cardTitle.copyWith(color: Colors.white)),
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

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyMain,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
