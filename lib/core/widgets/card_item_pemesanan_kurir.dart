import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  final String namaBarang;
  final String varian; // 🚀 TAMBAHAN: Variabel untuk Varian
  final String imageUrl;
  final int qty;
  final String harga;

  const OrderItemCard({
    super.key,
    required this.namaBarang,
    required this.varian, // 🚀 WAJIB DIISI
    required this.imageUrl,
    required this.qty,
    required this.harga,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment
              .start, // Ubah ke start biar rapi kalau teksnya panjang
          children: [
            // 🚀 GAMBAR BARANG DINAMIS DENGAN CLIPRRECT
            ClipRRect(
              borderRadius: BorderRadius.circular(12), // Dibikin lebih modern
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFAD510D).withOpacity(0.1),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFFAD510D),
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 🚀 DETAIL TEKS (Nama, Varian, Qty, Harga)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaBarang,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 🚀 NAMPILIN VARIAN KECIL DI BAWAHNYA
                  if (varian.isNotEmpty && varian != 'Default')
                    Text(
                      'Varian: $varian',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$qty item',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        harga,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAD510D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
        ),
      ],
    );
  }
}
