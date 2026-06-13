import 'package:flutter/material.dart';
import 'package:frontend/core/services/order_service.dart';
import 'package:frontend/core/models/order_model.dart';
import 'detailpesanan_kasir.dart'; 

class OrderKasir extends StatefulWidget {
  const OrderKasir({super.key});

  @override
  OrderKasirState createState() => OrderKasirState();
}

class OrderKasirState extends State<OrderKasir> {
  bool isOnlineTab = true; 
  List<OrderModel> ordersList = [];
  bool isLoading = true;
  String? errorMessage; 

  final OrderService _orderService = OrderService(); 

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final List<OrderModel> dataDariBackend = await _orderService.getDaftarPesanan();

      if (mounted) {
        setState(() {
          ordersList = dataDariBackend; 
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
      print("❌ Error memuat data dari backend: $e");
    }
  }

  Color _getStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'dikemas':
      case 'diproses': 
        return const Color(0xFFFFEDD5); 
      case 'selesai': 
      case 'dikirim':
        return const Color(0xFFDCFCE7); 
      default: 
        return const Color(0xFFE5E7EB); 
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'dikemas':
      case 'diproses': 
        return const Color(0xFFAF510C); 
      case 'selesai': 
      case 'dikirim':
        return const Color(0xFF15803D); 
      default: 
        return const Color(0xFF374151);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = ordersList.where((order) => order.isOnline == isOnlineTab).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "Daftar Pesanan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFAF510C),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), 
              color: const Color(0xFFAF510C),
            ),
            child: Row(
              children: [
                _buildTabButton("Online", true),
                _buildTabButton("Offline", false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: const Color(0xFFAF510C),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFAF510C)))
                  : errorMessage != null
                      ? _buildErrorWidget()
                      : filteredOrders.isEmpty
                          ? _buildEmptyWidget()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) => _buildOrderItem(filteredOrders[index]),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isOnline) {
    final bool isActive = isOnlineTab == isOnline;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isOnlineTab = isOnline),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive ? const Color(0xFFEAEFEF) : Colors.transparent,
          ),
          child: Text(
            label, 
            style: TextStyle(
              color: isActive ? const Color(0xFFAF510C) : Colors.white, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 56, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage ?? "Terjadi kesalahan sistem", 
                      style: const TextStyle(color: Colors.red, fontSize: 14), 
                      textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAF510C)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return LayoutBuilder(
      builder: (context, constraints) => ListView( 
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 52, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    "Belum ada pesanan ${isOnlineTab ? 'Online' : 'Offline'} saat ini",
                    style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tarik ke bawah untuk memperbarui",
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return GestureDetector(
      onTap: () {
        // 1. Ambil ID-nya (contoh: #ORD-AF7C0671)
        // 2. Kirim ke halaman DetailPesanan
        Navigator.push(
          context,
          MaterialPageRoute(
            // KODE BARU:
            builder: (context) => DetailPesanan(publicId: order.orderId), 
          ),
        );
      },
    child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8), 
              child: Image.network(
                order.imgUrl, 
                width: 52, 
                height: 52, 
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52, 
                  height: 52, 
                  color: const Color(0xFFF3EDE5),
                  child: const Icon(Icons.fastfood, color: Color(0xFFAF510C), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 14),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.orderId, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.statusText), 
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.statusText, 
                          style: TextStyle(
                            color: _getStatusTextColor(order.statusText), 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.itemsDetail, 
                    style: const TextStyle(color: Color(0xFF566067), fontSize: 14), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.timeInfo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(order.price, style: const TextStyle(color: Color(0xFFAF510C), fontWeight: FontWeight.bold)),
                    ],
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