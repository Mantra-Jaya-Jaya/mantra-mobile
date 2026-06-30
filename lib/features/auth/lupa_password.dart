// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/api_error.dart';

enum LupaPasswordStep { inputUsername, inputOtp, resetPassword, success }

class LupaPassword extends StatefulWidget {
  const LupaPassword({super.key});

  @override
  State<LupaPassword> createState() => _LupaPasswordState();
}

class _LupaPasswordState extends State<LupaPassword> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  LupaPasswordStep _currentStep = LupaPasswordStep.inputUsername;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _maskedEmail = "";

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = ApiClient().dio;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _animateToNextStep(LupaPasswordStep nextStep) {
    _animController.reverse().then((_) {
      setState(() {
        _currentStep = nextStep;
      });
      _animController.forward();
    });
  }

  // --- API CALLS ---

  Future<void> _kirimOTP() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await _dio.post('/auth/forgot-password', data: {
        'username': username,
      });
      
      if (response.statusCode == 200) {
        _maskedEmail = response.data['email'] ?? "***@***.com";
        _animateToNextStep(LupaPasswordStep.inputOtp);
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioException(e);
      _showError(apiError.userMessage);
    } catch (_) {
      _showError('Terjadi kesalahan koneksi.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifikasiOTP() async {
    final username = _usernameController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showError("Masukkan 6 digit OTP");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'username': username,
        'otp': otp,
      });
      
      if (response.statusCode == 200) {
        _animateToNextStep(LupaPasswordStep.resetPassword);
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioException(e);
      _showError(apiError.userMessage);
    } catch (_) {
      _showError('Terjadi kesalahan saat memverifikasi OTP.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final username = _usernameController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 8) {
      _showError("Password minimal 8 karakter");
      return;
    }
    if (password != confirm) {
      _showError("Konfirmasi password tidak cocok");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'username': username,
        'otp': otp,
        'password_baru': password,
        'konfirmasi_password': confirm,
      });
      
      if (response.statusCode == 200) {
        _animateToNextStep(LupaPasswordStep.success);
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioException(e);
      _showError(apiError.userMessage);
    } catch (_) {
      _showError('Terjadi kesalahan saat reset password.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAF510C),
      body: SafeArea(
        child: Stack(
          children: [
            // ===== BACKGROUND DEKORATIF =====
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // ===== KONTEN UTAMA =====
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case LupaPasswordStep.inputUsername:
        return _buildStep1Username();
      case LupaPasswordStep.inputOtp:
        return _buildStep2OTP();
      case LupaPasswordStep.resetPassword:
        return _buildStep3NewPassword();
      case LupaPasswordStep.success:
        return _buildStep4Success();
    }
  }

  // --- STEP 1: Username ---
  Widget _buildStep1Username() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildBackButton(),
          const SizedBox(height: 16),
          const Text(
            "Lupa Password?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFAF510C)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Masukkan username Anda. Kami akan mencari akun Anda dan mengirimkan OTP ke email yang terdaftar.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFAF510C), height: 1.5),
          ),
          const SizedBox(height: 28),
          _buildTextField(
            controller: _usernameController,
            hint: "Username",
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            text: "Cari Akun",
            onPressed: _kirimOTP,
            isActive: _usernameController.text.isNotEmpty,
          ),
        ],
      ),
    );
  }

  // --- STEP 2: OTP ---
  Widget _buildStep2OTP() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildBackButton(onTap: () => _animateToNextStep(LupaPasswordStep.inputUsername)),
          const SizedBox(height: 16),
          const Text(
            "Verifikasi OTP",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFAF510C)),
          ),
          const SizedBox(height: 8),
          Text(
            "Kode 6 digit telah dikirimkan ke email:\n$_maskedEmail",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFAF510C), height: 1.5),
          ),
          const SizedBox(height: 28),
          
          TextField(
            controller: _otpController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 32, 
              letterSpacing: 12, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFFAF510C)
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: "••••••",
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5), letterSpacing: 12),
              filled: true,
              fillColor: const Color(0xFFFAEDE4),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFAF510C), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildPrimaryButton(
            text: "Verifikasi Kode",
            onPressed: _verifikasiOTP,
            isActive: _otpController.text.length == 6,
          ),
        ],
      ),
    );
  }

  // --- STEP 3: New Password ---
  Widget _buildStep3NewPassword() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildBackButton(onTap: () => _animateToNextStep(LupaPasswordStep.inputOtp)),
          const SizedBox(height: 16),
          const Text(
            "Password Baru",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFAF510C)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Masukkan password baru Anda yang kuat dan mudah diingat.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFAF510C), height: 1.5),
          ),
          const SizedBox(height: 28),
          
          _buildPasswordField(
            controller: _passwordController,
            hint: "Password Baru",
            isObscure: _obscurePassword,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hint: "Konfirmasi Password",
            isObscure: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),

          const SizedBox(height: 24),
          _buildPrimaryButton(
            text: "Simpan Password",
            onPressed: _resetPassword,
            isActive: _passwordController.text.isNotEmpty && _confirmPasswordController.text.isNotEmpty,
          ),
        ],
      ),
    );
  }

  // --- STEP 4: Success ---
  Widget _buildStep4Success() {
    return _buildCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFAEDE4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFAF510C),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Password Diperbarui!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Anda sekarang dapat login menggunakan password yang baru.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAF510C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Back to Login Page",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBackButton({VoidCallback? onTap}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.pop(context),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFAF510C), size: 14),
            SizedBox(width: 6),
            Text(
              "Back",
              style: TextStyle(color: Color(0xFFAF510C), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFAF510C), size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAF510C), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAF510C), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFAF510C), size: 20),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAF510C), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAF510C), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    final canPress = isActive && !_isLoading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: canPress ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: canPress ? Colors.white : Colors.grey.shade100,
          side: BorderSide(
            color: canPress ? const Color(0xFFAF510C) : Colors.grey.shade300,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Color(0xFFAF510C), strokeWidth: 2.5),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFAF510C)),
              ),
      ),
    );
  }
}