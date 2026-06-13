import 'package:flutter/material.dart';
import '../../features/orders/detail_pengantaran_kurir.dart';
import '../models/pengantaran_model.dart';

enum CardVariant { newOrder, history, done }

class DeliveryCard extends StatelessWidget {
  final CardVariant variant;
  final PengantaranModel? data; 
  final String idPengantaran;

  const DeliveryCard({
    super.key,
    required this.idPengantaran,
    this.variant = CardVariant.newOrder,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    String displayOrderId = data != null && data!.publicId.length >= 8
        ? data!.publicId.substring(0, 8).toUpperCase()
        : 'IU790SE';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER ID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayOrderId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              _buildBadge(),
            ],
          ),
          const SizedBox(height: 10),

          // Konten Utama
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data?.namaCustomer.toUpperCase() ?? 'NAMA CUSTOMER',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data?.alamatLengkap ?? 'Alamat tidak ditemukan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Footer (Tombol Lihat Detail)
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPesananPage(
                      idPengantaran: idPengantaran,
                      isSedangDiantar: variant == CardVariant.history,
                      isSelesai: variant == CardVariant.done,
                    ),
                  ),
                );
              },
              child: const Text(
                'Lihat Detail',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAD510D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    String text = data?.status.toUpperCase() ?? 'PENGANTARAN';
    Color bgColor = variant == CardVariant.done
        ? Colors.grey.shade300
        : const Color(0xFFAD510D).withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
