// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';
import '../auth/services/auth_service.dart';
import '../auth/lupa_password.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';

class UbahPassword extends StatefulWidget {
  const UbahPassword({super.key});

  @override
  UbahPasswordState createState() => UbahPasswordState();
}

class UbahPasswordState extends State<UbahPassword> {
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isFormValid = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _oldPassController.addListener(_validateForm);
    _newPassController.addListener(_validateForm);
    _confirmPassController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _oldPassController.text.isNotEmpty &&
          _newPassController.text.isNotEmpty &&
          _confirmPassController.text.isNotEmpty;
    });
  }

  void _submitUbahPassword() async {
    if (!_isFormValid || _isLoading) return;

    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFAF510C)),
      ),
    );

    try {
      final dio = ApiClient().dio;
      final authService = AuthService(dio, const FlutterSecureStorage());
      await authService.changePassword(
        passwordLama: _oldPassController.text,
        passwordBaru: _newPassController.text,
        konfirmasiPassword: _confirmPassController.text,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password berhasil diubah"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);

      String errMsg = 'Gagal mengubah password';
      if (e is DioException && e.response?.data != null) {
        errMsg = e.response!.data['message'] ?? errMsg;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: "Ubah Password",
        leading: IconButton(
          onPressed: () => Navigator.pop(context),

          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 36),
        child: Column(
          children: [
            // Container Input Field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFFEAEFEF),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildField(
                    "Password Lama",
                    _oldPassController,
                    _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  const SizedBox(height: 15),
                  _buildField(
                    "Password Baru",
                    _newPassController,
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 15),
                  _buildField(
                    "Konfirmasi Password",
                    _confirmPassController,
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Link Lupa Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LupaPassword(),
                    ),
                  );
                },
                child: const Text(
                  "Lupa Password",
                  style: TextStyle(
                    color: Color(0xFFAF510C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isFormValid && !_isLoading
                    ? _submitUbahPassword
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAF510C),
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Simpan Password",
                  style: TextStyle(
                    color: _isFormValid && !_isLoading ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ================= SYARAT PASSWORD =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E7DD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8B08C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Syarat Password",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementItem("1. Min. 8 karakter"),
                  _buildRequirementItem("2. Kombinasi huruf & angka"),
                  _buildRequirementItem("3. Tidak sama dengan password lama"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: toggle,
              color: const Color(0xFFAF510C),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFAF510C)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFAF510C), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
