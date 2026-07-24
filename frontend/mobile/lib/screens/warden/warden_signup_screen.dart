import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';

class WardenSignupScreen extends StatefulWidget {
  const WardenSignupScreen({super.key});

  @override
  State<WardenSignupScreen> createState() => _WardenSignupScreenState();
}

class _WardenSignupScreenState extends State<WardenSignupScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _hostelNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _employeeIdController.dispose();
    _hostelNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final res = await authProvider.registerWarden(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        hostelName: _hostelNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account setup complete. You can now log in.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _errorMessage = res['error'] ?? res['message'] ?? 'An error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.navy : AppColors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Warden Sign Up', style: AppTextStyles.greeting),
                const SizedBox(height: 8),
                Text(
                  'Set up your warden account',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                    ),
                  ),

                Text('Authorized Email', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: AppTextStyles.bodyMain,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. warden@srishakthi.ac.in',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('First Name', style: AppTextStyles.bodySecondary),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firstNameController,
                            style: AppTextStyles.bodyMain,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Jane',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'First name required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last Name', style: AppTextStyles.bodySecondary),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lastNameController,
                            style: AppTextStyles.bodyMain,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Doe',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Employee ID', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _employeeIdController,
                  style: AppTextStyles.bodyMain,
                  decoration: const InputDecoration(
                    hintText: 'e.g. EMP1234',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Employee ID is required' : null,
                ),
                const SizedBox(height: 24),

                Text('Hostel Name', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hostelNameController,
                  style: AppTextStyles.bodyMain,
                  decoration: const InputDecoration(
                    hintText: 'e.g. A-Block',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Phone Number', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  style: AppTextStyles.bodyMain,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Password', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTextStyles.bodyMain,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text('Confirm Password', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTextStyles.bodyMain,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirm Password is required';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Complete Setup',
                  icon: Icons.check_circle_outline,
                  isLoading: _isLoading,
                  onPressed: _handleSignup,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
