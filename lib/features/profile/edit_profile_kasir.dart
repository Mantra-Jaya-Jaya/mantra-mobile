// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/services/kasir_profile_service.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';

class EditProfileKasir extends StatefulWidget {
  const EditProfileKasir({super.key});

  @override
  State<EditProfileKasir> createState() => _EditProfileKasirState();
}

class _EditProfileKasirState extends State<EditProfileKasir> {
  final KasirProfileService _kasirService = KasirProfileService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _telpController;
  late TextEditingController _emailController;
  late TextEditingController _alamatController;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _telpController = TextEditingController();
    _emailController = TextEditingController();
    _alamatController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _telpController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _kasirService.getProfil();
      _namaController.text = data['nama_lengkap'] ?? '';
      _telpController.text = data['no_telp'] ?? '';
      _emailController.text = data['email'] ?? '';
      _alamatController.text = data['alamat'] ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _kasirService.updateProfil(
        namaLengkap: _namaController.text,
        noTelp: _telpController.text,
        email: _emailController.text,
        alamat: _alamatController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: "Edit Profil Kasir",
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFAD510D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      icon: Icons.person_outline,
                      label: "Nama Lengkap",
                      controller: _namaController,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      icon: Icons.phone_outlined,
                      label: "No. Telepon",
                      controller: _telpController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      icon: Icons.email_outlined,
                      label: "Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      icon: Icons.location_on_outlined,
                      label: "Alamat",
                      controller: _alamatController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAD510D),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Simpan",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFEF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFAD510D)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: (v) => (v == null || v.trim().isEmpty) ? '$label tidak boleh kosong' : null,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
