// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/user_model.dart';
import '../../core/services/kasir_profile_service.dart';
import '../../core/widgets/base_header_widget.dart';
import '../auth/login.dart';
import 'edit_profile_kasir.dart';
import 'ubah_password.dart';

class ProfileKasir extends StatefulWidget {
  const ProfileKasir({super.key});

  @override
  ProfileKasirState createState() => ProfileKasirState();
}

class ProfileKasirState extends State<ProfileKasir> {
  final KasirProfileService _kasirService = KasirProfileService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isUploading = false;
  UserModel? _user;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _kasirService.getProfil();
      final user = UserModel.fromJson(data);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final String imageUrl = await _kasirService.uploadFoto(File(image.path));
      await _kasirService.updateProfil(fotoProfil: imageUrl);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil berhasil diperbarui")),
      );

      setState(() => _isUploading = false);
      _loadProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui foto profil: $e")),
      );
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshProfile() {
    _loadProfile();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0x1FAF510C), borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.logout, color: Color(0xFFAF510C), size: 42),
                ),
                const SizedBox(height: 18),
                const Text("Keluar dari Akun?", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Kamu yakin ingin keluar\ndari akun ini?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: Color(0xFFAF510C)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Tidak", style: TextStyle(color: Color(0xFFAF510C))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFFAF510C)),
                            ),
                          );
                          await _storage.deleteAll();
                          _kasirService.logout().catchError((error) {
                            debugPrint("API Logout error (ignored): $error");
                            return null;
                          });
                          if (!mounted) return;
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAF510C),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Iya", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout() {
    _showLogoutDialog();
  }

  Widget buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD8B08C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(title: 'Profile Kasir'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xFFAF510C)),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("Gagal memuat profil", style: TextStyle(color: Colors.grey.shade600)),
                      TextButton(
                        onPressed: _refreshProfile,
                        child: const Text("Coba Lagi", style: TextStyle(color: Color(0xFFAF510C))),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFAF510C), width: 3.0),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (_user!.fotoProfil != null && _user!.fotoProfil!.isNotEmpty) {
                          _showFullScreenImage(_user!.fotoProfil!);
                        }
                      },
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: (_user!.fotoProfil != null && _user!.fotoProfil!.isNotEmpty)
                            ? NetworkImage(_user!.fotoProfil!) as ImageProvider
                            : const AssetImage("assets/images/profile.jpg"),
                        child: _isUploading
                            ? const CircularProgressIndicator(color: Color(0xFFAF510C))
                            : null,
                      ),
                    ),
                  ),
                    Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAF510C),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.0),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, spreadRadius: 1)],
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                _user!.namaLengkap.isNotEmpty ? _user!.namaLengkap : 'Kasir',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                _user!.email.isNotEmpty ? _user!.email : '-',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    buildInfoTile(Icons.person, "Nama Lengkap", _user!.namaLengkap.isNotEmpty ? _user!.namaLengkap : 'Kasir'),
                    buildInfoTile(Icons.phone, "No. Telepon", _user!.noTelp.isNotEmpty ? _user!.noTelp : '-'),
                    buildInfoTile(Icons.email, "Email", _user!.email.isNotEmpty ? _user!.email : '-'),
                    buildInfoTile(Icons.person, "Username", _user!.username.isNotEmpty ? _user!.username : '-'),
                    buildInfoTile(Icons.location_on, "Alamat", _user!.alamat.isNotEmpty ? _user!.alamat : '-'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        "Aktif",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Edit Profil
              SizedBox(
                width: 300,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileKasir()),
                    );
                    if (result == true) _refreshProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAF510C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Edit Profil", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 12),

              // Ubah Password
              SizedBox(
                width: 300,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UbahPassword()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Ubah Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 12),

              // Logout
              SizedBox(
                width: 300,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFAF510C)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout, color: Color(0xFFAF510C)),
                  label: const Text("Keluar dari Akun", style: TextStyle(color: Color(0xFFAF510C), fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
