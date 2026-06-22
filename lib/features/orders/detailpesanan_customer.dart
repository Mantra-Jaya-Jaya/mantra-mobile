import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/base_header_widget.dart';
import '../cart/pembayaran_detail.dart';
import 'services/customer_order_service.dart';
import 'widgets/order_tracking_section.dart';

class OrderDetailPage extends StatefulWidget {
  final String noPesanan; // Ini adalah Public ID UUID

  const OrderDetailPage({
    super.key,
    required this.noPesanan,
    String? tampilanNoPesanan, // Parameter lama tetap ada agar tidak break
    String? namaProduk,
    String? statusLabel,
    Color? warnaStatus,
    String? tanggalPesanan,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final CustomerOrderService _orderService = CustomerOrderService();
  final GlobalKey<OrderTrackingSectionState> _trackingSectionKey =
      GlobalKey<OrderTrackingSectionState>();

  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final data = await _orderService.getOrderDetail(widget.noPesanan);

      if (mounted) {
        setState(() {
          _orderData = data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal memuat detail pesanan";
        });
      }
    }
  }

  Future<void> _refreshPage() async {
    await _fetchOrderDetail();
    await (_trackingSectionKey.currentState?.refresh() ?? Future.value());
  }

  void _scrollToTrackingSection() {
    final trackingContext = _trackingSectionKey.currentContext;
    if (trackingContext == null) return;

    Scrollable.ensureVisible(
      trackingContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  String _formatRupiah(int number) {
    final formatter = NumberFormat("#,###", "pt_BR");
    return 'Rp. ${formatter.format(number).replaceAll(',', '.')}';
  }

  String _normalizeStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu pembayaran':
      case 'belum dibayar':
        return 'Belum Dibayar';
      case 'dikemas':
        return 'Dikemas';
      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'menunggu pembayaran':
      case 'belum dibayar':
        return Colors.orange;
      case 'dikemas':
        return Colors.blue;
      case 'dikirim':
        return Colors.purple;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const BaseHeaderWidget(
          title: 'Detail Pesanan',
          leading: BackButton(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFAD510D)),
        ),
      );
    }

    if (_errorMessage != null || _orderData == null) {
      return Scaffold(
        appBar: const BaseHeaderWidget(
          title: 'Detail Pesanan',
          leading: BackButton(color: Colors.white),
        ),
        body: Center(child: Text(_errorMessage ?? "Pesanan tidak ditemukan")),
      );
    }

    final data = _orderData!;

    final items = (data['items'] as List? ?? []);
    final rincian = data['rincian_pembayaran'] as Map<String, dynamic>? ?? {};
    final status = _normalizeStatusLabel(
      (data['nama_status_pesanan'] ?? 'Pending').toString(),
    );
    final tujuan = data['tujuan_pengantaran'] as Map<String, dynamic>?;
    final kurir = data['kurir'] as Map<String, dynamic>?;
    final String publicId = data['no_pesanan'] ?? '-';

    final String displayOrderId = publicId.length >= 8
        ? publicId.substring(0, 8).toUpperCase()
        : publicId.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Detail Pesanan',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        color: const Color(0xFFAD510D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- NOMOR PESANAN & STATUS ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "No. Pesanan",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayOrderId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              OrderTrackingSection(
                key: _trackingSectionKey,
                noPesanan: widget.noPesanan,
              ),
              const SizedBox(height: 25),

              // --- DAFTAR BARANG ---
              Row(
                children: [
                  Icon(Icons.shopping_bag, color: const Color(0xFFAD510D)),
                  const SizedBox(width: 8),
                  const Text(
                    "Daftar Produk",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 30),
                  itemBuilder: (context, index) {
                    var item = items[index];
                    return Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            image: item['gambar'] != null
                                ? DecorationImage(
                                    image: NetworkImage(item['gambar']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: item['gambar'] == null
                              ? const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['nama_barang'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (item['varian'] != null)
                                Text(
                                  "Varian: ${item['varian']}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${item['jumlah']} x ${_formatRupiah(item['harga_satuan'] ?? 0)}",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(
                                      (item['harga_satuan'] ?? 0) *
                                          (item['jumlah'] ?? 0),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFFAD510D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),

              // --- METODE PEMBAYARAN ---
              Row(
                children: [
                  Icon(Icons.receipt, color: const Color(0xFFAD510D)),
                  const SizedBox(width: 8),
                  const Text(
                    "Informasi Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Metode",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        Text(
                          (rincian['metode'] != null &&
                                  rincian['metode'].toString().isNotEmpty)
                              ? rincian['metode'].toString().toUpperCase()
                              : 'BELUM TERPILIH',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (status == 'Belum Dibayar' ||
                        status == 'Menunggu Pembayaran') ...[
                      const Divider(height: 24),
                      const Text(
                        "Selesaikan pembayaran Anda segera untuk memproses pesanan ini.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PembayaranDetailPage(
                                  data: {
                                    'metode': rincian['metode'],
                                    'va_number': rincian['va_number'],
                                    'qr_url': rincian['qr_url'],
                                    'bill_key': rincian['bill_key'],
                                    'bill_code': rincian['bill_code'],
                                    'order_id': rincian['order_id'],
                                  },
                                  totalBayar: rincian['total'] ?? 0,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: const Text("Lihat Instruksi Pembayaran"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAD510D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // --- TUJUAN PENGANTARAN ---
              if (tujuan != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: const Color(0xFFAD510D)),
                    const SizedBox(width: 8),
                    const Text(
                      "Tujuan Pengantaran",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tujuan['nama_penerima'] ?? "-",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tujuan['alamat_lengkap'] ?? "-",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],

              // --- KURIR ---
              if (kurir != null) ...[
                const Text(
                  "Informasi Kurir",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            (kurir['foto_kurir'] != null &&
                                kurir['foto_kurir'].toString().isNotEmpty)
                            ? NetworkImage(kurir['foto_kurir'])
                            : null,
                        child:
                            (kurir['foto_kurir'] == null ||
                                kurir['foto_kurir'].toString().isEmpty)
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kurir['nama_kurir'] ?? "-",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (kurir['ekspedisi'] != null)
                            Text(
                              kurir['ekspedisi'],
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],

              // --- TOTAL RINCIAN ---
              const Text(
                "Rincian Biaya",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildRowTotal(
                      "Subtotal Produk",
                      _formatRupiah(rincian['subtotal_items'] ?? 0),
                    ),
                    const SizedBox(height: 8),
                    _buildRowTotal(
                      "Ongkos Kirim",
                      _formatRupiah(rincian['ongkir'] ?? 0),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Pembayaran",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatRupiah(rincian['total'] ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFFAD510D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- TOMBOL AKSI ---
              if (status == 'Belum Dibayar')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Batalkan Pesanan"),
                          content: const Text(
                            "Apakah Anda yakin ingin membatalkan pesanan ini?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Tidak"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Ya, Batalkan"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await _orderService.cancelOrder(widget.noPesanan);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Pesanan berhasil dibatalkan"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          _fetchOrderDetail();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Gagal membatalkan: $e"),
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Batalkan Pesanan"),
                  ),
                ),

              // Tombol Batalkan Pengiriman (untuk pesanan eksternal Biteship yang masih Dikemas)
              if (status == 'Dikemas')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelShipmentDialog(context),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text("Batalkan Pengiriman"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              if (status == 'Dikirim')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _scrollToTrackingSection,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text("Lacak Pesanan"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAD510D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowTotal(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          price,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showCancelShipmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Batalkan Pengiriman"),
        content: const Text(
          "Apakah Anda yakin ingin membatalkan pengiriman pesanan ini? "
          "Pesanan akan tetap ada tapi pengiriman via ekspedisi akan dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Tidak"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _orderService.cancelBiteshipShipment(widget.noPesanan);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengiriman berhasil dibatalkan"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh order detail
                  _fetchOrderDetail();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal membatalkan: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Ya, Batalkan"),
          ),
        ],
      ),
    );
  }
}
