// ignore_for_file: use_build_context_synchronously, deprecated_member_use
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

  // Menyimpan ID pesanan yang itemnya sedang dibuka (expanded)
  final Set<String> _expandedOrderIds = {};

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
      // Jika "Semua", kirim null. Jika status lain, kirim teksnya langsung ("Diproses", dll)
      final String? statusParam = selectedStatus == "Semua"
          ? null
          : selectedStatus;

      final orders = await _orderService.getOrders(status: statusParam);

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
          _expandedOrderIds.clear(); // Reset expand state
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
            SnackBar(
              content: const Text('Pesanan berhasil dibatalkan'),
              backgroundColor: primaryBrown,
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
                _buildTabItem("Dikemas"),
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
                : () {
                    // Terapkan filter di sisi frontend mengikuti data dari backend
                    final filteredOrders = selectedStatus == "Semua"
                        ? _orders
                        : _orders.where((order) {
                            String status =
                                (order['nama_status_pesanan'] ?? '').toString();
                            if (status == 'Menunggu Pembayaran') {
                              status = 'Belum Dibayar';
                            }
                            return status == selectedStatus;
                          }).toList();

                    if (filteredOrders.isEmpty) {
                      return Center(
                        child: Text(
                          "Belum ada pesanan ${selectedStatus.toLowerCase()}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: primaryBrown,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredOrders.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filteredOrders.length) {
                            return const SizedBox(height: 80);
                          }
                          final order = filteredOrders[index];
                          return _buildOrderCardFromData(order);
                        },
                      ),
                    );
                  }(),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'belum dibayar':
      case 'menunggu pembayaran':
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

  Widget _buildOrderCardFromData(Map<String, dynamic> order) {
    final String publicId = order['id_pesanan'] ?? '-';

    String statusAsli = order['nama_status_pesanan'] ?? 'Belum Dibayar';
    if (statusAsli == 'Menunggu Pembayaran') {
      statusAsli = 'Belum Dibayar';
    }
    final int totalBayar = order['total_bayar'] ?? 0;
    final List items = order['items'] ?? [];
    final int itemCount = items.length;

    final String displayOrderId = publicId.length >= 8
        ? publicId.substring(0, 8).toUpperCase()
        : publicId.toUpperCase();

    bool isExpanded = _expandedOrderIds.contains(publicId);

    final List itemsToShow = isExpanded
        ? items
        : (items.isNotEmpty ? [items[0]] : []);

    String tanggalStr = "-";
    if (order['tanggal_pesan'] != null) {
      try {
        final rawDateStr = order['tanggal_pesan'].toString();
        final date = DateTime.parse(rawDateStr);
        tanggalStr = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      } catch (error) {
        debugPrint("Gagal parsing tanggal");
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
            builder: (context) => OrderDetailPage(noPesanan: publicId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blueGrey.shade50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER KARTU (ID & STATUS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "No. Pesanan",
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      Text(
                        displayOrderId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusAsli).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusAsli,
                    style: TextStyle(
                      color: _getStatusColor(statusAsli),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // LIST ITEM
            if (itemsToShow.isEmpty)
              const Text(
                "Tidak ada item produk",
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemsToShow.length,
                separatorBuilder: (context, i) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = itemsToShow[i];
                  final String itemName = item['nama_barang'] ?? 'Produk';
                  final String itemImage = item['gambar'] ?? '';
                  final int qty = item['jumlah'] ?? 1;

                  return Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: itemImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  itemImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "$qty barang",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

            // TOMBOL LIHAT SELENGKAPNYA
            if (itemCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedOrderIds.remove(publicId);
                      } else {
                        _expandedOrderIds.add(publicId);
                      }
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isExpanded
                            ? "Sembunyikan"
                            : "Lihat ${itemCount - 1} produk lainnya",
                        style: TextStyle(
                          color: primaryBrown,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: primaryBrown,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 24, thickness: 0.5),

            // FOOTER KARTU (DENGAN AKSI TOMBOL)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tanggalStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(totalBayar),
                      style: TextStyle(
                        color: primaryBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (statusAsli == "Belum Dibayar" ||
                        statusAsli == "Menunggu Pembayaran") ...[
                      SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: () => _cancelOrder(publicId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(
                              color: Colors.red,
                              width: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Batalkan",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
