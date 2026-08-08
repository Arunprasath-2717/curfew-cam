import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_service.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTabIndex = 0; // 0: Student, 1: Warden, 2: Watchman
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('ag_remembered_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleBiometricLogin() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) return;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        _emailController.text = 'admin@test.com';
        _passwordController.text = 'testpass';
        await _handleLogin('admin_warden');
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
    }
  }

  Future<void> _handleLogin([String? overrideRole]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final String requestedRole = overrideRole ?? (_selectedTabIndex == 0 ? 'student' : (_selectedTabIndex == 1 ? 'warden' : 'watchman'));
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final res = await authProvider.login(_emailController.text, _passwordController.text, requestedRole);
      
      if (!mounted) return;
      
      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('ag_remembered_email', _emailController.text);
        } else {
          await prefs.remove('ag_remembered_email');
        }
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, authProvider.dashboardRoute, (route) => false);
        }
      } else {
        setState(() => _errorMessage = res['message']);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFastLogin(String email, String role) async {
    _emailController.text = email;
    _passwordController.text = 'Password123';
    await _handleLogin(role);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = AppColors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64.0),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // 1. Top Section
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.camera_outdoor, color: AppColors.white, size: 24),
                      ),
                      const SizedBox(height: 24),
                      Text('Welcome back', style: AppTextStyles.greeting),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to manage your outpasses',
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 32),

                      // 2. Role Selector Tabs
                      Row(
                        children: [
                          _buildRoleTab(0, 'Student'),
                          _buildRoleTab(1, 'Warden'),
                          _buildRoleTab(2, 'Watchman'),
                        ],
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

                      // 3. Form Fields
                      Text(_selectedTabIndex == 2 ? 'Phone Number' : 'College Email', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: _selectedTabIndex == 2 ? TextInputType.phone : TextInputType.emailAddress,
                        style: AppTextStyles.bodyMain,
                        decoration: InputDecoration(
                          hintText: _selectedTabIndex == 2 ? 'e.g. 9998887770' : 'e.g. 21bs042@univ.edu',
                          prefixIcon: Icon(_selectedTabIndex == 2 ? Icons.phone : Icons.alternate_email),
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
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: const BorderSide(color: AppColors.textSecondary),
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: AppTextStyles.bodyMain),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 4. Submit Button
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Login',
                              icon: Icons.arrow_forward,
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: _handleBiometricLogin,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).primaryColor),
                              ),
                              child: Icon(Icons.fingerprint, color: Theme.of(context).primaryColor, size: 32),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_selectedTabIndex == 0) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: AppTextStyles.bodyMain.copyWith(color: AppColors.textSecondary),
                                children: [
                                  TextSpan(
                                    text: 'Register',
                                    style: AppTextStyles.bodyMain.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),

                      // 5. Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('SECURE CAMPUS LOGIN', style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary)),
                          ),
                          Expanded(child: Divider(color: AppColors.inputBorder, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(child: Text('FAST LOGIN (TESTING)', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).primaryColor))),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                              onPressed: () => _handleFastLogin('student1@test.com', 'student'),
                              child: const Text('Student 1'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                              onPressed: () => _handleFastLogin('warden1@test.com', 'warden'),
                              child: const Text('Warden 1'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                              onPressed: () => _handleFastLogin('9998887770', 'watchman'),
                              child: const Text('Watchman 1'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                              onPressed: () => _handleFastLogin('admin@test.com', 'admin_warden'),
                              child: const Text('Admin Warden'),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),


                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleTab(int index, String title) {
    final bool isActive = _selectedTabIndex == index;
    final primaryColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? primaryColor : AppColors.inputBorder,
                width: isActive ? 2.0 : 1.0,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: AppTextStyles.bodyMain.copyWith(
                color: isActive ? primaryColor : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
