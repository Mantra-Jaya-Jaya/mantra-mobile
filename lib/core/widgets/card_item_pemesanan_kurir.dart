import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  final String namaBarang;
  final int qty;
  final String harga;

  const OrderItemCard({
    super.key,
    required this.namaBarang,
    required this.qty,
    required this.harga,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon Box
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFAD510D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFFAD510D),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Detail Teks
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$qty item',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    harga,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 🚀 3. JARAK PEMBATAS ANTAR ITEM DIPANGKAS
        const Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
          ), // Disusutkan dari 16 jadi 8
          child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
        ),
      ],
    );
  }
}
