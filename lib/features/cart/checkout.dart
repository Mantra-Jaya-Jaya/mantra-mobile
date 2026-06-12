import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import '../orders/services/customer_order_service.dart';
import '../orders/order_customer.dart';
import 'pilih_alamat.dart';
import 'pilih_pembayaran.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import '../home/home_customer.dart';
import 'package:dio/dio.dart';

class Checkout extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;

  const Checkout({super.key, required this.selectedProducts});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final ProfileService _profileService = ProfileService();
  final CustomerOrderService _orderService = CustomerOrderService();
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _alamatDipilih;
  Map<String, dynamic>? _pembayaranDipilih;

  @override
  void initState() {
    super.initState();
    // Default awal di-set ke Mantra-pay
    _pembayaranDipilih = {
      'kategori': 'mantrapay',
      'id_metode': 'mantrapay',
      'nama': 'Mantra-pay',
      'sub': 'Saldo Rp. 120.000',
      'icon': Icons.wallet_rounded,
    };
    _ambilAlamatDariBackend();
  }

  Future<void> _ambilAlamatDariBackend() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final daftarAlamatDariBackend = await _profileService.getAlamat();

      if (mounted) {
        setState(() {
          _alamatDipilih = daftarAlamatDariBackend.firstWhere(
            (addr) => addr['is_utama'] == true || addr['is_utama'] == 1,
            orElse: () => daftarAlamatDariBackend.isNotEmpty
                ? daftarAlamatDariBackend.first
                : {},
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error ambil alamat checkout: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Gagal mengambil alamat utama dari server.";
        });
      }
    }
  }

  int get subtotalProduk {
    int total = 0;
    for (var item in widget.selectedProducts) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    return total;
  }

  int get ongkosKirim =>
      _alamatDipilih != null && _alamatDipilih!.isNotEmpty ? 25000 : 0;
  int get pajak => 5000;
  int get totalPembayaran => subtotalProduk + ongkosKirim + pajak;

  String _formatRupiah(int number) {
    return 'Rp. ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _prosesBuatPesanan() async {
    if (_alamatDipilih == null || _alamatDipilih!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tambahkan alamat pengiriman terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final items = widget.selectedProducts.map((item) {
        return {'id_spesifikasi_barang': item['id'], 'qty': item['quantity']};
      }).toList();

      await _orderService.checkout(
        idAlamat: _alamatDipilih!['id_alamat'].toString(),
        metodePembayaran: _pembayaranDipilih?['id_metode'] ?? 'mantrapay',
        grandTotal: totalPembayaran,
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan Berhasil Disimpan!'),
            backgroundColor: Color(0xFFAD510D),
          ),
        );
        // Navigasi ke HomeScreen dengan index 2 (Halaman Pesanan) dan hapus stack sebelumnya
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(initialIndex: 2),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print(
        "KESALAHAN SEBELUM POST: $e",
      ); // Tambahkan ini untuk melihat error sebenarnya
      String errorMsg = "Gagal membuat pesanan";
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pindahKePilihAlamat() async {
    final alamatBaruTerpilih = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PilihAlamatPage(alamatSekarang: _alamatDipilih),
      ),
    );

    if (alamatBaruTerpilih != null &&
        alamatBaruTerpilih is Map<String, dynamic>) {
      setState(() {
        _alamatDipilih = alamatBaruTerpilih;
      });
    }
  }

  Future<void> _pindahKePilihPembayaran() async {
    final pembayaranBaru = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PilihPembayaranPage(pembayaranSekarang: _pembayaranDipilih),
      ),
    );

    if (pembayaranBaru != null && pembayaranBaru is Map<String, dynamic>) {
      setState(() {
        _pembayaranDipilih = pembayaranBaru;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Checkout',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFAD510D)),
              )
            : Column(
                children: [
                  // Konten utama list checkout
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ...widget.selectedProducts.map(
                          (item) => _buildCheckoutProductTile(item),
                        ),
                        const SizedBox(height: 10),

                        // Sub Header Alamat
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFAD510D),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Alamat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildAlamatBackendCard(),
                        const SizedBox(height: 24),

                        // Sub Header Metode Pembayaran
                        const Row(
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              color: Color(0xFFAD510D),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tampilan Metode Pembayaran (Otomatis berubah dinamis mengikuti sub-pilihan)
                        _buildPembayaranCard(),
                        const SizedBox(height: 24),

                        // Header Rincian Biaya
                        const Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: Color(0xFFAD510D),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rincian Biaya',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildNotaRincianCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatRupiah(totalPembayaran),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAD510D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _prosesBuatPesanan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Buat Pesanan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutProductTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: item['image'] != null && item['image'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: item['image'].toString().startsWith('http')
                        ? Image.network(
                            item['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image,
                                color: Colors.grey,
                              );
                            },
                          )
                        : Image.asset(item['image'], fit: BoxFit.cover),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  item['subtitle'],
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatRupiah(item['price']),
                      style: const TextStyle(
                        color: Color(0xFFAD510D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Qty: ${item['quantity']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlamatBackendCard() {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_alamatDipilih == null || _alamatDipilih!.isEmpty) {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3F4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Belum ada alamat dipilih.",
              style: TextStyle(color: Colors.grey),
            ),
            GestureDetector(
              onTap: _pindahKePilihAlamat,
              child: const Text(
                'Pilih',
                style: TextStyle(
                  color: Color(0xFFAD510D),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33AD510D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _alamatDipilih!['label_alamat'] ?? 'Alamat',
                  style: const TextStyle(
                    color: Color(0xFFAD510D),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _pindahKePilihAlamat,
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    color: Color(0xFFAD510D),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _alamatDipilih!['nama_penerima'] ?? 'Penerima',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            _alamatDipilih!['alamat_lengkap'] ?? '-',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPembayaranCard() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFAD510D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _pembayaranDipilih?['icon'] ?? Icons.wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SINKRON: Menampilkan nama sub-bank/sub-wallet terpilih secara spesifik
                  Text(
                    _pembayaranDipilih?['nama'] ?? 'Metode Pembayaran',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _pembayaranDipilih?['sub'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: _pindahKePilihPembayaran,
            child: const Text(
              'Ubah',
              style: TextStyle(
                color: Color(0xFFAD510D),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaRincianCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _notaRow('Subtotal', _formatRupiah(subtotalProduk)),
          const SizedBox(height: 10),
          _notaRow('Ongkos Kirim', _formatRupiah(ongkosKirim)),
          const SizedBox(height: 10),
          _notaRow('Pajak', _formatRupiah(pajak)),
          const Divider(height: 24, thickness: 0.5, color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                _formatRupiah(totalPembayaran),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFAD510D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ],
    );
  }
}
