import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/watch_background.dart';

enum AuthScreenState {
  signIn,
  signUp,
  forgotPassword,
  checkEmail,
  resetPassword,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = Get.find<AuthController>();

  AuthScreenState _currentState = AuthScreenState.signIn;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  final String _selectedRole = "user";
  final String _selectedPlan = "free";

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar("Invalid Email", "Please enter a valid email address.");
      return;
    }
    if (password.isEmpty) {
      Get.snackbar("Missing Password", "Please enter your password.");
      return;
    }

    debugPrint("📱 [LOGIN SCREEN] User submitted Sign In -> Email: '$email'");
    final success = await _authController.login(
      _nameController.text.trim(),
      _selectedRole,
      _selectedPlan,
      email: email,
      password: password,
    );
    if (success) {
      debugPrint("📱 [LOGIN SCREEN] Sign in successful. Navigating to /home");
      Get.offAllNamed('/home');
    } else {
      debugPrint("⚠️ [LOGIN SCREEN] Sign in failed.");
    }
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    debugPrint("📱 [LOGIN SCREEN] User submitted Register -> Name: '$name', Email: '$email'");
    if (name.isEmpty) {
      Get.snackbar("Missing Name", "Please enter your display name.");
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar("Invalid Email", "Please enter a valid email address.");
      return;
    }
    if (password.length < 8) {
      Get.snackbar("Short Password", "Password must be at least 8 characters.");
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar("Mismatch", "Passwords do not match.");
      return;
    }

    final success = await _authController.register(
      name,
      email,
      password,
      role: _selectedRole,
      plan: _selectedPlan,
    );
    if (success) {
      debugPrint("📱 [LOGIN SCREEN] Registration successful. Navigating to /home");
      Get.offAllNamed('/home');
    } else {
      debugPrint("⚠️ [LOGIN SCREEN] Registration failed.");
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    debugPrint("📱 [LOGIN SCREEN] User submitted Forgot Password -> Email: '$email'");
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar("Invalid Email", "Please enter your registered email address.");
      return;
    }
    await _authController.forgotPassword(email);
    setState(() => _currentState = AuthScreenState.checkEmail);
  }



  @override
  Widget build(BuildContext context) {
    final bool showBackArrow = _currentState == AuthScreenState.forgotPassword ||
        _currentState == AuthScreenState.signUp ||
        _currentState == AuthScreenState.checkEmail ||
        _currentState == AuthScreenState.resetPassword;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: WatchBackground(
        showDialTicks: true,
        showGears: true,
        isDark: context.isDarkTheme,
        child: Stack(
          children: [
            // Main Scroll View Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      // Brand Header Section
                      Text(
                        "The Watch Box",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: context.isDarkTheme ? Colors.white : const Color(0xFF07274C),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "PRECISION HOROLOGY MARKETPLACE",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Animated State Switcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.04),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildStateWidget(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Top-left Back Arrow Button
            if (showBackArrow)
              Positioned(
                top: 48,
                left: 16,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: context.textSecondaryColor, size: 26),
                  onPressed: () {
                    setState(() {
                      _currentState = AuthScreenState.signIn;
                    });
                  },
                ),
              ),


          ],
        ),
      ),
    );
  }

  // Switches between widgets based on state
  Widget _buildStateWidget() {
    switch (_currentState) {
      case AuthScreenState.signIn:
        return _buildSignInState();
      case AuthScreenState.signUp:
        return _buildSignUpState();
      case AuthScreenState.forgotPassword:
        return _buildForgotPasswordState();
      case AuthScreenState.checkEmail:
        return _buildCheckEmailState();
      case AuthScreenState.resetPassword:
        return _buildResetPasswordState();
    }
  }

  // Reusable Elevated Card Shell matching screenshots
  Widget _buildAuthCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
      decoration: BoxDecoration(
        color: context.isDarkTheme ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // Reusable Form Input Field matching screenshots
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14.5,
        color: context.textPrimaryColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF334155),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: context.isDarkTheme ? AppColors.backgroundDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
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

  // Reusable Primary Action Button
  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF07274C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // 1. SIGN IN STATE
  Widget _buildSignInState() {
    return Column(
      key: const ValueKey("signIn"),
      children: [
        _buildAuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Access your luxury watch collection & market insights.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),

              // Email Address
              _buildInputField(
                controller: _emailController,
                hintText: "Email Address",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password
              _buildInputField(
                controller: _passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  child: GestureDetector(
                    onTap: () => setState(() => _currentState = AuthScreenState.forgotPassword),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF07274C),
                      ),
                    ),
                  ),
                ),
              ),

              // Sign In Button
              _buildPrimaryButton(
                text: "Sign In",
                onPressed: _handleSignIn,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Footer Link
        GestureDetector(
          onTap: () => Get.toNamed('/signup'),
          behavior: HitTestBehavior.opaque,
          child: RichText(
            text: const TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
              ),
              children: [
                TextSpan(
                  text: "Sign Up",
                  style: TextStyle(
                    color: Color(0xFF07274C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. CREATE ACCOUNT STATE
  Widget _buildSignUpState() {
    return Column(
      key: const ValueKey("signUp"),
      children: [
        _buildAuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Join certified collectors & trade timepieces globally.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),

              // Display Name
              _buildInputField(
                controller: _nameController,
                hintText: "Display Name",
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              // Email Address
              _buildInputField(
                controller: _emailController,
                hintText: "Email Address",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password
              _buildInputField(
                controller: _passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 14),

              // Confirm Password
              _buildInputField(
                controller: _confirmPasswordController,
                hintText: "Confirm Password",
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 24),

              // Register Button
              _buildPrimaryButton(
                text: "Register Account",
                onPressed: _handleRegister,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Footer Link
        GestureDetector(
          onTap: () => setState(() => _currentState = AuthScreenState.signIn),
          behavior: HitTestBehavior.opaque,
          child: RichText(
            text: const TextSpan(
              text: "Already have an account? ",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
              ),
              children: [
                TextSpan(
                  text: "Sign In",
                  style: TextStyle(
                    color: Color(0xFF07274C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. RESET PASSWORD STATE
  Widget _buildForgotPasswordState() {
    return Column(
      key: const ValueKey("forgotPassword"),
      children: [
        _buildAuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Enter your email address to receive reset instructions.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),

              // Email Address
              _buildInputField(
                controller: _emailController,
                hintText: "Email Address",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Send Reset Link Button
              _buildPrimaryButton(
                text: "Send Reset Link",
                onPressed: _handleForgotPassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Footer Link
        GestureDetector(
          onTap: () => setState(() => _currentState = AuthScreenState.signIn),
          behavior: HitTestBehavior.opaque,
          child: RichText(
            text: const TextSpan(
              text: "Already have an account? ",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
              ),
              children: [
                TextSpan(
                  text: "Sign In",
                  style: TextStyle(
                    color: Color(0xFF07274C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. CHECK EMAIL STATE
  Widget _buildCheckEmailState() {
    return Column(
      key: const ValueKey("checkEmail"),
      children: [
        _buildAuthCard(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF07274C).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 32,
                  color: Color(0xFF07274C),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Check Your Email",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We sent password reset instructions to ${_emailController.text.trim().isEmpty ? 'your email' : _emailController.text.trim()}.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _buildPrimaryButton(
                text: "Back to Sign In",
                onPressed: () => setState(() => _currentState = AuthScreenState.signIn),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. RESET PASSWORD INPUT STATE (Direct)
  Widget _buildResetPasswordState() {
    return _buildForgotPasswordState();
  }
}


