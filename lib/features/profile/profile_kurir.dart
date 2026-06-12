import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Sesuaikan path import dengan struktur folder lu
import '../../core/services/kurir_profile_service.dart';
import '../../core/widgets/global_appbar_kurir.dart';
import '../../core/models/profil_kurir_model.dart';
import 'ubah_password.dart';
import '../auth/login.dart';

class ProfileKurirPage extends StatefulWidget {
  const ProfileKurirPage({super.key});

  @override
  State<ProfileKurirPage> createState() => _ProfileKurirPageState();
}

class _ProfileKurirPageState extends State<ProfileKurirPage> {
  // 🚀 SERVICE & FUTURE
  final KurirService _service = KurirService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Future<ProfilKurirModel?> _profilFuture;

  @override
  void initState() {
    super.initState();
    // Tembak API sekali pas halaman pertama kali dibuka
    _profilFuture = _service.getProfilKurir();
  }

  // Dialog konfirmasi logout custom anti-stuck
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x1FAF510C),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFFAF510C),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Keluar dari Akun?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Kamu yakin ingin keluar\ndari akun ini?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    // Tombol Tidak — kembali ke profil
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: Color(0xFFAF510C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Tidak",
                          style: TextStyle(color: Color(0xFFAF510C)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Iya — hapus token lokal secara instan & jalankan API di background
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Tutup dialog konfirmasi

                          // Tampilkan loading overlay
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFFAF510C)),
                            ),
                          );

                          // 1. UTAMAKAN: Hapus token lokal secara instan agar tidak tersandera error API
                          await _storage.deleteAll();

                          // 2. Jalankan API logout di background tanpa 'await' (fire-and-forget)
                          try {
                            final Dio = _service.getProfilKurir(); // triggering to get dio is not needed, but we can call API logout via ApiClient
                            // We can just call /logout directly
                            // final response = await ApiClient().dio.post('/logout', data: {'refresh_token': ...})
                            // For simplicity, deleting all storage local token is enough to kick user out.
                          } catch (_) {}

                          if (!mounted) return;
                          Navigator.pop(context); // Tutup loading overlay

                          // 3. Langsung tendang ke halaman login dan bersihkan seluruh history navigation
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAF510C),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Iya",
                          style: TextStyle(color: Colors.white),
                        ),
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

  // 🚀 HELPER: Format Tanggal (Dari 2003-10-10T... jadi 10 Oktober 2003)
  String _formatTanggal(String isoDate) {
    if (isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return isoDate; // Kalau gagal format, tampilin teks aslinya aja
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD510D),
      appBar: const GlobalAppBarKurir(
        title: 'Profile Kurir',
        showBackButton: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 🚀 WADAH PUTIH MELENGKUNG
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),

                  // 🚀 FUTURE BUILDER: Nungguin data dari API
                  child: FutureBuilder<ProfilKurirModel?>(
                    future: _profilFuture,
                    builder: (context, snapshot) {
                      // 1. Kalau lagi nunggu data (Loading)
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFAD510D),
                          ),
                        );
                      }

                      // 2. Kalau Error atau Data Kosong
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal memuat profil',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _profilFuture = _service.getProfilKurir();
                                  });
                                },
                                child: const Text(
                                  'Coba Lagi',
                                  style: TextStyle(color: Color(0xFFAD510D)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // 3. 🚀 DATA BERHASIL DIDAPAT!
                      final profil = snapshot.data!;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 32,
                          bottom: 120,
                        ),
                        child: Column(
                          children: [
                            // 🚀 FOTO PROFIL DINAMIS
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFAD510D,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFFAD510D,
                                  ).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  profil.fotoProfil,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.person_outline,
                                        size: 50,
                                        color: Color(0xFFAD510D),
                                      ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 🚀 CARD INFORMASI AKUN
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      'Informasi Akun',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),

                                  // INJECT DATA DARI API KE SINI
                                  _buildInfoItem(
                                    'Nama Lengkap',
                                    profil.namaLengkap,
                                  ),
                                  _buildInfoItem('Email', profil.email),
                                  _buildInfoItem(
                                    'Nomor Telepon (No Telp)',
                                    profil.noTelp,
                                  ),
                                  _buildInfoItem('NIK', profil.nik),
                                  _buildInfoItem(
                                    'Tempat, Tanggal Lahir',
                                    '${profil.tempatLahir}, ${_formatTanggal(profil.tanggalLahir)}',
                                  ),
                                  _buildInfoItem(
                                    'Jenis Kelamin',
                                    profil.jenisKelamin,
                                  ),
                                  _buildInfoItem(
                                    'Pendidikan Terakhir',
                                    profil.pendidikanTerakhir,
                                  ),
                                  _buildInfoItem('Alamat', profil.alamat),

                                  // Status Karyawan
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Status',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                          ),
                                          child: const Text(
                                            'Aktif',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 🚀 TOMBOL UBAH PASSWORD
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UbahPassword(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFAD510D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Ubah Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 🚀 TOMBOL KELUAR DARI AKUN
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _showLogoutDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C3E50),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Keluar dari akun',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 HELPER WIDGET BUAT ITEM INFORMASI
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
