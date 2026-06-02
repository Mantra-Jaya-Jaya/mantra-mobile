import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
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
                  // 2. Harga Produk (Mendukung Logika Diskon)
                  if (barang.punyaDiskon) ...[
                    Text(
                      currencyFormat.format(barang.hargaTerendah),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      currencyFormat.format(barang.hargaDiskon),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                  ] else ...[
                    Text(
                      currencyFormat.format(barang.hargaTerendah),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 3. Nama Produk
                  Text(
                    barang.namaBarang,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const Divider(height: 30, thickness: 1),

                  // 4. Deskripsi / Informasi Tambahan
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informasi detail mengenai ${barang.namaBarang}. Stok dan varian unit konformable dengan sistem gudang MANTRA.',
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
    );
  }
}
