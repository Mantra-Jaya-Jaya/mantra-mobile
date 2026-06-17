import 'package:flutter/material.dart';
import 'services/customer_order_service.dart';
import '../../core/widgets/base_header_widget.dart';
import '../cart/pembayaran_detail.dart';
import 'order_tracking_page.dart';
import 'package:intl/intl.dart';

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

  String _formatRupiah(int number) {
    final formatter = NumberFormat("#,###", "pt_BR");
    return 'Rp. ${formatter.format(number).replaceAll(',', '.')}';
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
        appBar: const BaseHeaderWidget(title: 'Detail Pesanan', leading: BackButton(color: Colors.white)),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFAD510D))),
      );
    }

    if (_errorMessage != null || _orderData == null) {
      return Scaffold(
        appBar: const BaseHeaderWidget(title: 'Detail Pesanan', leading: BackButton(color: Colors.white)),
        body: Center(child: Text(_errorMessage ?? "Pesanan tidak ditemukan")),
      );
    }

    final data = _orderData!;
    final items = (data['items'] as List? ?? []);
    final rincian = data['rincian_pembayaran'] as Map<String, dynamic>? ?? {};
    final status = data['nama_status_pesanan'] ?? 'Pending';
    final tujuan = data['tujuan_pengantaran'] as Map<String, dynamic>?;
    final kurir = data['kurir'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Detail Pesanan',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
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
                        data['no_pesanan'] ?? widget.noPesanan,
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
                      color: _getStatusColor(status).withOpacity(0.15),
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

            // --- DAFTAR BARANG ---
            const Text(
              "Daftar Produk",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                separatorBuilder: (context, index) => const Divider(height: 30),
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
                          image: item['gambar'] != null ? DecorationImage(
                            image: NetworkImage(item['gambar']),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: item['gambar'] == null ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey) : null,
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
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${item['jumlah']} x ${_formatRupiah(item['harga_satuan'] ?? 0)}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatRupiah((item['harga_satuan'] ?? 0) * (item['jumlah'] ?? 0)),
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
            const Text(
              "Informasi Pembayaran",
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Metode", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        (rincian['metode'] != null && rincian['metode'].toString().isNotEmpty) 
                            ? rincian['metode'].toString().toUpperCase() 
                            : 'BELUM TERPILIH',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  if (status == 'Belum Dibayar' || status == 'Menunggu Pembayaran') ...[
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              const Text(
                "Tujuan Pengantaran",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      backgroundImage: (kurir['foto_kurir'] != null && kurir['foto_kurir'].toString().isNotEmpty) 
                          ? NetworkImage(kurir['foto_kurir']) 
                          : null,
                      child: (kurir['foto_kurir'] == null || kurir['foto_kurir'].toString().isEmpty) 
                          ? const Icon(Icons.person, color: Colors.grey) 
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kurir['nama_kurir'] ?? "-",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (kurir['ekspedisi'] != null)
                          Text(
                            kurir['ekspedisi'],
                            style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
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
                  _buildRowTotal("Subtotal Produk", _formatRupiah(rincian['subtotal_items'] ?? 0)),
                  const SizedBox(height: 8),
                  _buildRowTotal("Ongkos Kirim", _formatRupiah(rincian['ongkir'] ?? 0)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pembayaran",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    // Logika batalkan pesanan
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Batalkan Pesanan"),
                ),
              ),
            
            if (status == 'Dikirim')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingPage(noPesanan: widget.noPesanan),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text("Lacak Pesanan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowTotal(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Text(price, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
