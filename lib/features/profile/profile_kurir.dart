import 'package:flutter/material.dart';
import '../../core/widgets/global_appbar_kurir.dart'; 

class ProfileKurirPage extends StatelessWidget {
  const ProfileKurirPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🚀 1. Ubah background dasar jadi coklat biar nyatu sama AppBar
      backgroundColor: const Color(0xFFAD510D),

      // 🚀 APP BAR (Pakai komponen global biar seragam)
      appBar: const GlobalAppBarKurir(
        title: 'Profile Kurir',
        showBackButton: false, // Tanpa panah karena ini tab utama
      ),

      // 🚀 KONTEN UTAMA
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Kasih sedikit jarak antara AppBar dan Lengkungan (opsional, biar mirip desain tugas)
            const SizedBox(height: 16),

            // 🚀 2. WADAH PUTIH MELENGKUNG SAKTI
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30), // Ini yang bikin gak kaku!
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 32,
                      bottom:
                          120, // Spasi ekstra biar gak ketabrak Bottom Nav Induk
                    ),
                    child: Column(
                      children: [
                        // 🚀 IKON PROFILE
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFAD510D).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_outline,
                              size: 50,
                              color: Color(0xFFAD510D),
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
                              Divider(height: 1, color: Colors.grey.shade200),

                              _buildInfoItem('Nama Lengkap', 'Aji Santoso'),
                              _buildInfoItem('Email', 'aji.kurir@mantra.com'),
                              _buildInfoItem(
                                'Nomor Telepon (No Telp)',
                                '081234567890',
                              ),
                              _buildInfoItem('NIK', '3374012345678901'),
                              _buildInfoItem(
                                'Tempat, Tanggal Lahir',
                                'Semarang, 14 April 1998',
                              ),
                              _buildInfoItem('Jenis Kelamin', 'Laki-laki'),
                              _buildInfoItem('Pendidikan Terakhir', 'SMA/SMK'),
                              _buildInfoItem(
                                'Alamat',
                                'Griya Candi Bahagia, Jl. Cempaka Kayu No.39, Semarang, Jawa Tengah',
                              ),

                              // Status Karyawan
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        borderRadius: BorderRadius.circular(12),
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
                            onPressed: () {},
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
                            onPressed: () {},
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
