import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/base_header_widget.dart';
import 'detailpesanan_customer.dart';
import 'services/customer_order_service.dart';

class MyOrderPage extends StatefulWidget {
  const MyOrderPage({super.key});

  @override
  State<MyOrderPage> createState() => _MyOrderPageState();
}

class _MyOrderPageState extends State<MyOrderPage> {
  final CustomerOrderService _orderService = CustomerOrderService();
  String selectedStatus = "Semua";
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  // Warna Cokelat Utama Aplikasi
  final Color primaryBrown = const Color(0xFFAD510D);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      // Map frontend status to backend status
      String? backendStatus;
      if (selectedStatus == "Belum Dibayar") {
        backendStatus = "menunggu_pembayaran";
      } else if (selectedStatus == "Diproses") {
        backendStatus = "diproses";
      } else if (selectedStatus == "Dikirim") {
        backendStatus = "dikirim";
      } else if (selectedStatus == "Selesai") {
        backendStatus = "selesai";
      } else if (selectedStatus == "Dibatalkan") {
        backendStatus = "dibatalkan";
      }

      final orders = await _orderService.getOrders(status: backendStatus);
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data pesanan: $e')),
        );
      }
    }
  }

  Future<void> _cancelOrder(String publicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Batalkan Pesanan"),
        content: const Text("Apakah Anda yakin ingin membatalkan pesanan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Tidak", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Ya, Batalkan",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _orderService.cancelOrder(publicId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil dibatalkan'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchOrders(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membatalkan pesanan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(title: "Pesanan Saya"),
      body: Column(
        children: [
          // TAB SECTION (Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildTabItem("Semua"),
                _buildTabItem("Belum Dibayar"),
                _buildTabItem("Diproses"),
                _buildTabItem("Dikirim"),
                _buildTabItem("Selesai"),
                _buildTabItem("Dibatalkan"),
              ],
            ),
          ),

          // ORDER LIST
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBrown))
                : _orders.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada pesanan ${selectedStatus.toLowerCase()}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchOrders,
                    color: primaryBrown,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _orders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _orders.length) {
                          return const SizedBox(height: 80);
                        }
                        final order = _orders[index];
                        return _buildOrderCardFromData(order);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title) {
    bool isSelected = selectedStatus == title;

    return GestureDetector(
      onTap: () {
        if (selectedStatus != title) {
          setState(() {
            selectedStatus = title;
          });
          _fetchOrders();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryBrown : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.transparent),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryBrown,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCardFromData(Map<String, dynamic> order) {
    final String publicId = order['id_pesanan'] ?? '-';
    final String nomorPesanan = order['nomor_pesanan'] ?? publicId;
    final String statusBackend = order['status'] ?? 'menunggu_pembayaran';
    final int totalBayar = order['total_bayar'] ?? 0;
    final List items = order['items'] ?? [];
    final String firstItemName = items.isNotEmpty
        ? items[0]['nama_barang']
        : 'Produk';
    final String firstItemImage = items.isNotEmpty
        ? items[0]['gambar'] ?? ''
        : '';
    final int itemCount = items.length;

    // --- PERBAIKAN 1: Menyamakan mapping status dengan format database backend (lowercase) ---
    String statusLabel = "Belum Dibayar";
    if (statusBackend == "diproses") {
      statusLabel = "Diproses";
    } else if (statusBackend == "dikirim") {
      statusLabel = "Dikirim";
    } else if (statusBackend == "selesai") {
      statusLabel = "Selesai";
    } else if (statusBackend == "dibatalkan") {
      statusLabel = "Dibatalkan";
    }

    final Color statusColor = primaryBrown;

    // Format Tanggal
    String tanggalStr = "-";
    if (order['tanggal_pesanan'] != null) {
      try {
        final rawDateStr = order['tanggal_pesanan'].toString();
        final date = DateTime.parse(rawDateStr);
        tanggalStr = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      } catch (error) {
        print(
          "Gagal parsing tanggal untuk order $nomorPesanan. Data asli: ${order['tanggal_pesanan']}. Error: $error",
        );
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(
              noPesanan: publicId,
              tampilanNoPesanan: nomorPesanan,
              namaProduk: firstItemName,
              statusLabel: statusLabel,
              warnaStatus: statusColor,
              tanggalPesanan: tanggalStr,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blueGrey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ORDER ID",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      Text(
                        nomorPesanan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: firstItemImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            firstItemImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.book, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.book, color: Colors.grey),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "$itemCount item",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currencyFormat.format(totalBayar),
                        style: const TextStyle(
                          color: Color(0xFFAD510D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tanggalStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                // Mengatur aksi tombol ke halaman detail atau fungsi batal
                ElevatedButton(
                  onPressed: () {
                    // Memicu aksi navigasi yang sama dengan tap card (Membuka Detail)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(
                          noPesanan: publicId,
                          tampilanNoPesanan: nomorPesanan,
                          namaProduk: firstItemName,
                          statusLabel: statusLabel,
                          warnaStatus: statusColor,
                          tanggalPesanan: tanggalStr,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Detail", style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
