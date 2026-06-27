// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../features/orders/detail_pengantaran_kurir.dart';
import '../models/pengantaran_model.dart';

enum CardVariant { newOrder, history, done }

class DeliveryCard extends StatelessWidget {
  final CardVariant variant;
  final String idPengantaran;
  final PengantaranModel? data;
  final bool isTibaDiTujuan;

  const DeliveryCard({
    super.key,
    required this.idPengantaran,
    this.variant = CardVariant.newOrder,
    this.data,
    this.isTibaDiTujuan = false,
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
            color: Colors.black.withValues(alpha: 0.05),
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
                      _getCardHeader(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getCardSubHeader(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
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
                      isSedangDiantar: variant == CardVariant.history && !isTibaDiTujuan,
                      isSelesai: variant == CardVariant.done,
                      isTibaDiTujuan: isTibaDiTujuan,
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

  String _getCardHeader() {
    final status = (data?.statusLabel ?? '').toLowerCase();
    if (status == 'menunggu') {
      return 'Ambil di: Toko Mantra Basecamp';
    } else if (status == 'selesai') {
      return 'Selesai Dikirim ke: ${(data?.namaCustomer ?? 'CUSTOMER').toUpperCase()}';
    }
    return 'Kirim ke: ${(data?.namaCustomer ?? 'CUSTOMER').toUpperCase()}';
  }

  String _getCardSubHeader() {
    final status = (data?.statusLabel ?? '').toLowerCase();
    if (status == 'menunggu') {
      return 'Kirim ke: ${(data?.namaCustomer ?? 'CUSTOMER').toUpperCase()}\n${data?.alamatLengkap ?? ''}';
    }
    return data?.alamatLengkap ?? 'Alamat tidak ditemukan';
  }

  Widget _buildBadge() {
    String text = data?.statusLabel ?? 'Menunggu';
    
    // Sesuaikan warna dengan palet coklat
    Color bgColor = variant == CardVariant.done
        ? const Color(0xFFAD510D).withValues(alpha: 0.15) // Light brown for done
        : const Color(0xFFAD510D); // Solid brown for active

    Color textColor = variant == CardVariant.done
        ? const Color(0xFFAD510D)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
