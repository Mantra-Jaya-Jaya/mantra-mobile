import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/features/home/services/cart_service.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';

class DetailBarangPage extends StatelessWidget {
  final BarangModel barang;

  const DetailBarangPage({super.key, required this.barang});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: 'Detail Barang',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gambar Produk
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey.shade100,
              child: barang.gambarBarang.isNotEmpty
                  ? Image.network(barang.gambarBarang, fit: BoxFit.cover)
                  : const Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 1. NAMA & HARGA BARANG (SEJAJAR HORIZONTAL)
                  // ==========================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Membuat teks rata atas jika nama barang panjang
                    children: [
                      // Nama Barang (Menggunakan Expanded agar fleksibel dan tidak overflow)
                      Expanded(
                        child: Text(
                          barang.namaBarang,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ), // Jarak horizontal antara nama dan harga
                      // Harga Barang (Logika Diskon / Harga Utama)
                      Text(
                        barang.punyaDiskon
                            ? currencyFormat.format(barang.hargaDiskon)
                            : currencyFormat.format(barang.hargaTerendah),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAD510D), // Warna cokelat tema MANTRA
                        ),
                      ),
                    ],
                  ),

                  // ==========================================
                  // 2. HARGA CORET (Hanya tampil jika ada diskon)
                  // ==========================================
                  if (barang.punyaDiskon) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment
                          .topRight, // Menyejajarkan harga coret di bawah harga diskon
                      child: Text(
                        currencyFormat.format(barang.hargaTerendah),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ==========================================
                  // 3. STOK BARANG
                  // ==========================================
                  Row(
                    children: [
                      const Icon(Icons.shelves, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Stok: 24 pcs', // Nanti ganti dengan data dinamis: 'Stok: ${barang.stok}'
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32, thickness: 1),

                  // ==========================================
                  // 4. VARIAN PRODUK
                  // ==========================================
                  const Text(
                    'Pilih Varian',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      _buildVariantChip('S', isSelected: false),
                      _buildVariantChip('M', isSelected: true),
                      _buildVariantChip('L', isSelected: false),
                      _buildVariantChip('XL', isSelected: false),
                    ],
                  ),

                  const Divider(height: 32, thickness: 1),

                  // ==========================================
                  // 5. DESKRIPSI PRODUK
                  // ==========================================
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    barang.deskripsi.isNotEmpty
                        ? barang.deskripsi
                        : 'Tidak ada deskripsi tersedia untuk produk ini.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Bagian Tombol Aksi di Bawah Layar (Sejajar Horizontal)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(
                0,
                -3,
              ), // Memberikan efek bayangan ke atas container
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Tombol Masukkan Keranjang (Ikon Saja)
              OutlinedButton(
                onPressed: () async {
                  try {
                    // Tampilkan loading kecil atau langsung eksekusi post
                    await CartService().addToCart(
                      idBarang: barang.idBarang,
                      quantity: 1, // Default tambah 1
                      idVarian:
                          null, // Masukkan variabel ID Varian jika nanti fitur varian aktif
                    );

                    // Berhasil post ke backend Golang
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${barang.namaBarang} berhasil masuk ke keranjang di database!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    // Handle jika gagal (misal server mati / timeout)
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gagal menambahkan ke keranjang. Coba lagi.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFAD510D), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFFAD510D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12), // Jarak antar tombol
              // Tombol Beli Sekarang (Expanded agar memenuhi sisa ruang)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implementasi logika checkout langsung
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Beli Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildVariantChip(String label, {required bool isSelected}) {
  return ChoiceChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (secure) {
      // TODO: Masukkan logika ketika varian diklik / diubah state-nya
    },
    selectedColor: const Color(0xFFAD510D).withOpacity(0.15),
    backgroundColor: Colors.grey.shade50,
    labelStyle: TextStyle(
      color: isSelected ? const Color(0xFFAD510D) : Colors.black87,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      fontSize: 13,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(
        color: isSelected ? const Color(0xFFAD510D) : Colors.grey.shade300,
        width: isSelected ? 1.5 : 1,
      ),
    ),
    showCheckmark:
        false, // Menghilangkan ikon centang bawaan Flutter agar UI bersih
  );
}
