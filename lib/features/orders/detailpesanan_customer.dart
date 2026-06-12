import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/widgets/base_header_widget.dart';
import 'services/customer_order_service.dart';

class OrderDetailPage extends StatefulWidget {
  final String noPesanan;
  final String? tampilanNoPesanan;
  final String namaProduk;
  final String statusLabel;
  final Color warnaStatus;
  final String tanggalPesanan;

  const OrderDetailPage({
    super.key,
    required this.noPesanan,
    this.tampilanNoPesanan,
    required this.namaProduk,
    required this.statusLabel,
    required this.warnaStatus,
    required this.tanggalPesanan,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final CustomerOrderService _orderService = CustomerOrderService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _orderDetail;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final detail = await _orderService.getOrderDetail(widget.noPesanan);

      if (mounted) {
        setState(() {
          _orderDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal memuat detail pesanan: ${e.toString()}";
        });
      }
    }
  }

  String _formatRupiah(int number) {
    return 'Rp. ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _tampilkanLacakPesananBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>>(
              future: _orderService.getTracking(widget.noPesanan),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFAD510D)),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'Gagal mengambil data pelacakan',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final tracking = snapshot.data!;
                final tipe = tracking['tipe_ekspedisi'] ?? 'internal';

                if (tipe == 'eksternal') {
                  final history = tracking['history'] as List<dynamic>? ?? [];
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lacak: ${tracking['ekspedisi'] ?? 'Ekspedisi'}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Text(
                          'No. Resi: ${tracking['nomor_resi'] ?? '-'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const Divider(height: 24),
                        Expanded(
                          child: history.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Belum ada riwayat pengiriman.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: history.length,
                                  itemBuilder: (context, index) {
                                    final ev = history[index];
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFAD510D),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            if (index < history.length - 1)
                                              Container(
                                                width: 2,
                                                height: 50,
                                                color: Colors.grey.shade300,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ev['description'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${ev['time'] ?? ''} - ${ev['city'] ?? ''}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Internal tracking map
                  final kurir = tracking['kurir'] as Map<String, dynamic>?;
                  final lokasi = tracking['lokasi_kurir'] as Map<String, dynamic>?;
                  final lat = (lokasi?['latitude'] as num?)?.toDouble() ?? 0.0;
                  final lng = (lokasi?['longitude'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lacak Kurir Toko',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        if (kurir != null) ...[
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: kurir['foto'] != null && kurir['foto'].toString().isNotEmpty
                                    ? NetworkImage(kurir['foto'].toString())
                                    : null,
                                child: kurir['foto'] == null || kurir['foto'].toString().isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kurir['nama'] ?? 'Kurir Toko',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    kurir['plat_nomor'] ?? 'Kurir Internal',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        Expanded(
                          child: (lat == 0.0 && lng == 0.0)
                              ? const Center(
                                  child: Text(
                                    'Kurir belum memulai perjalanan atau lokasi tidak tersedia.',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(lat, lng),
                                      initialZoom: 15.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.mantrajayajaya.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(lat, lng),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.motorcycle,
                                              color: Color(0xFFAD510D),
                                              size: 30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: BaseHeaderWidget(
          title: 'Detail Pesanan',
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFAD510D)),
        ),
      );
    }

    if (_errorMessage != null || _orderDetail == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: BaseHeaderWidget(
          title: 'Detail Pesanan',
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage ?? "Pesanan tidak ditemukan",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final items = _orderDetail!['items'] as List<dynamic>? ?? [];
    final tujuan = _orderDetail!['tujuan_pengantaran'] as Map<String, dynamic>?;
    final kurir = _orderDetail!['kurir'] as Map<String, dynamic>?;
    final rincian = _orderDetail!['rincian_pembayaran'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Colors.white,
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
            Row(
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
                      widget.tampilanNoPesanan ?? widget.noPesanan,
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
                    color: widget.warnaStatus.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _orderDetail!['status'] ?? widget.statusLabel,
                    style: TextStyle(
                      color: widget.warnaStatus,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1),

            // --- DAFTAR BARANG ---
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                var item = items[index];
                return Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: item['gambar'] != null && item['gambar'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item['gambar'].toString(),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.inventory, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['nama_barang'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${item['jumlah'] ?? 1} item ${item['varian'] != null && item['varian'].toString().isNotEmpty ? '(${item['varian']})' : ''}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRupiah((item['harga_satuan'] ?? 0) as int),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 35, thickness: 1),

            // --- TUJUAN PENGANTARAN ---
            const Text(
              "Tujuan Pengantaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            tujuan == null
                ? Text(
                    "Ambil di Toko",
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  )
                : Column(
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
                      const SizedBox(height: 2),
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
            const Divider(height: 35, thickness: 1),

            // --- EKSPEDISI / KURIR ---
            if (kurir != null) ...[
              const Text(
                "Info Pengiriman",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: kurir['foto_kurir'] != null && kurir['foto_kurir'].toString().isNotEmpty
                        ? NetworkImage(kurir['foto_kurir'].toString())
                        : null,
                    child: kurir['foto_kurir'] == null || kurir['foto_kurir'].toString().isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kurir['nama_kurir'] ?? 'Kurir Pengirim',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (kurir['plat_nomor'] != null && kurir['plat_nomor'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          kurir['plat_nomor'].toString(),
                          style: const TextStyle(color: Colors.black87, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        kurir['ekspedisi'] ?? "Internal Toko",
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 35, thickness: 1),
            ],

            // --- TOTAL RINCIAN ---
            const Text(
              "Rincian Pembayaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (rincian != null) ...[
              _buildRowTotal("Subtotal Items", "", _formatRupiah((rincian['subtotal_items'] ?? 0) as int)),
              _buildRowTotal("Ongkos Kirim", "", _formatRupiah((rincian['ongkir'] ?? 0) as int)),
              _buildRowTotal("Biaya Proteksi", "", _formatRupiah((rincian['biaya_proteksi'] ?? 0) as int)),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    _formatRupiah((rincian['total'] ?? 0) as int),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),

            // --- TOMBOL LACAK PESANAN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tampilkanLacakPesananBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD510D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Lacak Pesanan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowTotal(String label, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              qty,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Text(price, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }
}
