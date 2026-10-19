import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/watch_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthController _authController = Get.find<AuthController>();

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: "United States");
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Form toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // Major country list for selection
  static const List<String> _countries = [
    "United States",
    "Switzerland",
    "United Kingdom",
    "United Arab Emirates",
    "Japan",
    "Germany",
    "Singapore",
    "France",
    "Italy",
    "Hong Kong",
    "Canada",
    "Australia",
    "Bangladesh",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password Strength Calculator
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password) || RegExp(r'[!@#\$&*~%^+=_-]').hasMatch(password)) strength++;
    return strength; // 0 to 4
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 1:
        return "Weak (Add mixed case & length)";
      case 2:
        return "Fair (Add numbers or symbols)";
      case 3:
        return "Good";
      case 4:
        return "Strong (Optimal Security)";
      default:
        return "Enter at least 8 characters";
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF3B82F6);
      case 4:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _openCountryPicker() {
    final isDark = context.isDarkTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.public, color: context.textPrimaryColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      "Select Country / Hub",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: _countries.length,
                  separatorBuilder: (ctx, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (ctx, index) {
                    final country = _countries[index];
                    final isSelected = _countryController.text.trim() == country;
                    return ListTile(
                      title: Text(
                        country,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF07274C)
                              : context.textPrimaryColor,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF07274C))
                          : null,
                      onTap: () {
                        setState(() {
                          _countryController.text = country;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final country = _countryController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Field Validations
    if (name.isEmpty || name.length < 2) {
      Get.snackbar(
        "Display Name Required",
        "Display name must be at least 2 characters.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      Get.snackbar(
        "Invalid Email",
        "Please provide a valid email address.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    if (password.length < 8) {
      Get.snackbar(
        "Weak Password",
        "Password must be at least 8 characters.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        "Password Mismatch",
        "Passwords do not match. Please re-enter carefully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }

    if (!_agreeToTerms) {
      Get.snackbar(
        "Terms & Conditions",
        "Please agree to the Terms of Service & Privacy Policy to continue.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade800,
        colorText: Colors.white,
      );
      return;
    }

    debugPrint("📱 [SIGN UP SCREEN] Submitting Registration -> Name: '$name' | Email: '$email' | Phone: '$phone' | Country: '$country'");

    final success = await _authController.register(
      name,
      email,
      password,
      phone: phone.isNotEmpty ? phone : null,
      country: country.isNotEmpty ? country : null,
    );

    if (success) {
      debugPrint("📱 [SIGN UP SCREEN] Registration successful! Redirecting to /home");
      Get.offAllNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkTheme;
    final passwordStrength = _calculatePasswordStrength(_passwordController.text);
    final passwordsMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: WatchBackground(
        showDialTicks: true,
        showGears: true,
        isDark: isDark,
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      // Top Brand Header
                      Text(
                        "The Watch Box",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF07274C),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "AUTHENTICATED LUXURY WATCH PLATFORM",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Sign Up Card Shell
                      _buildSignUpCard(isDark, passwordStrength, passwordsMatch),
                      const SizedBox(height: 24),

                      // Footer Navigation Link
                      GestureDetector(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Get.offAllNamed('/login');
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF07274C),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),

            // Top-left Back Arrow
            Positioned(
              top: 48,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.textSecondaryColor, size: 26),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Get.offAllNamed('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpCard(bool isDark, int passwordStrength, bool passwordsMatch) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF07274C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF07274C).withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  "SECURE API",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF07274C),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Enter your details to create an authenticated account.",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // Display Name / Full Name (Required by backend API)
          _buildFieldLabel("Full Name / Display Name *"),
          _buildInputField(
            controller: _nameController,
            hintText: "e.g. John Horologist",
            prefixIcon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Email Address (Required by backend API)
          _buildFieldLabel("Email Address *"),
          _buildInputField(
            controller: _emailController,
            hintText: "collector@example.com",
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Phone Number (Supported by profile)
          _buildFieldLabel("Phone Number (Optional)"),
          _buildInputField(
            controller: _phoneController,
            hintText: "+1 (555) 000-0000",
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),

          // Country / Location Hub (Supported by API)
          _buildFieldLabel("Country / Regional Hub"),
          GestureDetector(
            onTap: _openCountryPicker,
            child: AbsorbPointer(
              child: _buildInputField(
                controller: _countryController,
                hintText: "Select your country",
                prefixIcon: Icons.public_rounded,
                suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Password (Required by backend API, min 8 chars)
          _buildFieldLabel("Password * (Min 8 characters)"),
          _buildInputField(
            controller: _passwordController,
            hintText: "Enter secure password",
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // Password Strength Bar
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (index) {
                final isFilled = index < passwordStrength;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? _getStrengthColor(passwordStrength)
                          : (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 5),
            Text(
              _getStrengthLabel(passwordStrength),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _getStrengthColor(passwordStrength),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Confirm Password
          _buildFieldLabel("Confirm Password *"),
          _buildInputField(
            controller: _confirmPasswordController,
            hintText: "Re-enter your password",
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: _obscureConfirmPassword,
            onChanged: (_) => setState(() {}),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (passwordsMatch)
                  const Padding(
                    padding: EdgeInsets.only(right: 6.0),
                    child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                  ),
                IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Terms and Conditions Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreeToTerms,
                  activeColor: const Color(0xFF07274C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                  child: const Text(
                    "I accept the Terms of Service, Authenticity Guidelines & Privacy Policy.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Primary Register Button with Reactive Loading State
          Obx(() {
            final isLoading = _authController.isLoading.value;
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07274C),
                  disabledBackgroundColor: const Color(0xFF07274C).withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.how_to_reg_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Complete Registration",
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14.5,
        color: context.textPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF475569),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: context.borderColor,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF07274C),
            width: 1.6,
          ),
        ),
      ),
    );
  }
}
