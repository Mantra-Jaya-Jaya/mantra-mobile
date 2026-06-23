import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/customer_order_service.dart';
import '../../core/widgets/base_header_widget.dart';
import '../cart/pembayaran_detail.dart';
import 'widgets/order_tracking_section.dart';

class OrderDetailPage extends StatefulWidget {
  final String noPesanan; // Ini adalah Public ID UUID

  const OrderDetailPage({
    super.key,
    required this.noPesanan,
    String? tampilanNoPesanan,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.black87;
      case 'menunggu pembayaran':
      case 'belum dibayar':
      case 'dikemas':
      case 'dikirim':
        return const Color(0xFFAD510D);
      case 'dibatalkan':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
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

  String _formatPaymentMethod(Map<String, dynamic> rincian) {
    if (rincian['metode'] == null || rincian['metode'].toString().isEmpty) {
      return 'BELUM TERPILIH';
    }
    
    final String metode = rincian['metode'].toString();
    final String namaBank = (rincian['nama_bank'] ?? '').toString();
    
    if (metode == 'bank_transfer' || metode == 'echannel') {
      if (namaBank.isNotEmpty) {
        return '$namaBank Virtual Account';
      }
      return 'Transfer Bank';
    } else if (metode == 'qris') {
      return 'QRIS';
    } else if (metode == 'gopay') {
      return 'GoPay';
    } else if (metode == 'tunai' || metode == 'cash') {
      if (rincian['kanal_pembayaran'] == 'cod') {
        return 'COD (Bayar di Tempat)';
      }
      return 'Tunai (Cash)';
    }
    
    return metode.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        appBar: BaseHeaderWidget(
          title: 'Detail Pesanan',
          leading: BackButton(color: Colors.white),
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFAD510D)),
        ),
      );
    }

    if (_errorMessage != null || _orderData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
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
    final isCashPayment = (rincian['metode'] ?? '').toString().toLowerCase() == 'cash';
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "No. Pesanan",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayOrderId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
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
                Icon(Icons.shopping_bag_outlined, color: const Color(0xFFAD510D), size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Daftar Produk",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 30, color: Colors.black12),
                itemBuilder: (context, index) {
                  var item = items[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                          image: item['gambar'] != null && item['gambar'].toString().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(item['gambar']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (item['gambar'] == null || item['gambar'].toString().isEmpty)
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
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item['varian'] != null && item['varian'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "Varian: ${item['varian']}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${item['jumlah']} x ${_formatRupiah(item['harga_satuan'] ?? 0)}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    _formatRupiah(
                                      (item['harga_satuan'] ?? 0) *
                                          (item['jumlah'] ?? 0),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFFAD510D),
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                Icon(Icons.receipt_long_outlined, color: const Color(0xFFAD510D), size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Informasi Pembayaran",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
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
                      Expanded(
                        child: Text(
                          _formatPaymentMethod(rincian),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (status == 'Belum Dibayar' ||
                      status == 'Menunggu Pembayaran' || isCashPayment) ...[
                    const Divider(height: 30, color: Colors.black12),
                    if (isCashPayment) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAD510D).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.money_outlined, color: Color(0xFFAD510D), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Bayar saat kurir tiba menggunakan uang tunai.\n"
                                "Siapkan uang pas untuk memudahkan transaksi.",
                                style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAD510D).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFAD510D), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Selesaikan pembayaran Anda segera untuk memproses pesanan ini.",
                                style: TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PembayaranDetailPage(
                                  data: {
                                    'metode': rincian['metode'],
                                    'nama_bank': rincian['nama_bank'],
                                    'kanal_pembayaran': rincian['kanal_pembayaran'],
                                    'va_number': rincian['va_number'],
                                    'qr_url': rincian['qr_url'],
                                    'bill_key': rincian['bill_key'],
                                    'bill_code': rincian['bill_code'],
                                    'order_id': rincian['order_id'],
                                    'public_id_pesanan': widget.noPesanan,
                                    'batas_waktu': rincian['batas_waktu'],
                                  },
                                  totalBayar: rincian['total'] ?? 0,
                                ),
                              ),
                            );
                            if (result == true) {
                              _fetchOrderDetail();
                            }
                          },
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: const Text(
                            "Lihat Instruksi Pembayaran",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAD510D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- TUJUAN PENGANTARAN ---
            if (tujuan != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: const Color(0xFFAD510D), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Tujuan Pengantaran",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      color: Colors.black87,
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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tujuan['nama_penerima'] ?? "-",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tujuan['alamat_lengkap'] ?? "-",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],

            // --- KURIR ---
            if (kurir != null && kurir.isNotEmpty && kurir['nama_kurir'] != null) ...[
              Row(
                children: [
                  Icon(Icons.delivery_dining_outlined, color: const Color(0xFFAD510D), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Informasi Kurir",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.black12),
                        image: (kurir['foto_kurir'] != null &&
                                kurir['foto_kurir'].toString().isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(kurir['foto_kurir']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (kurir['foto_kurir'] == null ||
                              kurir['foto_kurir'].toString().isEmpty)
                          ? const Icon(Icons.person_outline, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kurir['nama_kurir'] ?? "-",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          if (kurir['ekspedisi'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              kurir['ekspedisi'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],

            // --- TOTAL RINCIAN ---
            Row(
              children: [
                Icon(Icons.summarize_outlined, color: const Color(0xFFAD510D), size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Rincian Biaya",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildRowTotal(
                    "Subtotal Produk",
                    _formatRupiah(rincian['subtotal_items'] ?? 0),
                  ),
                  const SizedBox(height: 10),
                  _buildRowTotal(
                    "Ongkos Kirim",
                    _formatRupiah(rincian['ongkir'] ?? 0),
                  ),
                  const Divider(height: 30, color: Colors.black12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pembayaran",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _formatRupiah(rincian['total'] ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFAD510D),
                          ),
                          overflow: TextOverflow.ellipsis,
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Batalkan Pesanan",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            if (status == 'Dikemas' && !isCashPayment)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelShipmentDialog(context),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text(
                    "Batalkan Pengiriman",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                  label: const Text(
                    "Lacak Pesanan",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
            if (status == 'Selesai' && rincian['kurir'] != null && rincian['kurir']['foto_bukti_pengiriman'] != null && rincian['kurir']['foto_bukti_pengiriman'].toString().isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFAD510D),
                                ),
                                width: double.infinity,
                                child: const Text(
                                  "Bukti Pengiriman",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Image.network(
                                rincian['kurir']['foto_bukti_pengiriman'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  );
                                },
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Tutup",
                                  style: TextStyle(
                                    color: Color(0xFFAD510D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text(
                    "Lihat Bukti Pengiriman",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFAD510D),
                    side: const BorderSide(color: Color(0xFFAD510D)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
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
        Flexible(
          child: Text(
            price,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
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
