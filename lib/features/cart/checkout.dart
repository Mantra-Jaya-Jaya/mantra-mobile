import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/customer_checkout_service.dart';
import '../../core/models/metode_pembayaran_model.dart';
import 'pilih_alamat.dart';
import 'pilih_pembayaran.dart';

class Checkout extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;

  const Checkout({super.key, required this.selectedProducts});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final ProfileService _profileService = ProfileService();
  final CustomerCheckoutService _checkoutService = CustomerCheckoutService();
  bool _isLoading = true;
  bool _isLoadingMetode = true;
  bool _isLoadingOngkir = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  Map<String, dynamic>? _alamatDipilih;
  Map<String, dynamic>? _pembayaranDipilih;
  List<MetodePembayaran> _daftarMetode = [];

  List<dynamic> _daftarEkspedisi = [];
  Map<String, dynamic>? _ekspedisiDipilih;
  Map<String, dynamic>? _layananDipilih;
  final TextEditingController _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pembayaranDipilih = null;
    _ambilAlamatDariBackend();
    _ambilMetodePembayaran();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
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
            orElse: () => daftarAlamatDariBackend.isNotEmpty ? daftarAlamatDariBackend.first : {},
          );
          _isLoading = false;
        });
        if (_alamatDipilih != null && _alamatDipilih!.isNotEmpty) {
          _cekOngkir();
        }
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

  Future<void> _ambilMetodePembayaran() async {
    try {
      final metode = await _checkoutService.getMetodePembayaran();
      if (mounted) {
        setState(() {
          _daftarMetode = metode;
          _isLoadingMetode = false;
        });
      }
    } catch (e) {
      print("Error ambil metode bayar: $e");
      if (mounted) {
        setState(() => _isLoadingMetode = false);
      }
    }
  }

  Future<void> _cekOngkir() async {
    if (_alamatDipilih == null || _alamatDipilih!.isEmpty) return;
    setState(() => _isLoadingOngkir = true);

    try {
      final items = widget.selectedProducts.map((item) {
        return {
          'id_spesifikasi_barang': item['id_spesifikasi_barang'] ?? item['id'],
          'quantity': item['quantity'],
        };
      }).toList();

      final response = await _checkoutService.cekOngkir(
        idAlamat: _alamatDipilih!['public_id'] ?? _alamatDipilih!['id_alamat'],
        items: items,
      );
      if (mounted) {
        setState(() {
          _daftarEkspedisi = response['data'] ?? [];
          _isLoadingOngkir = false;
        });
      }
    } catch (e) {
      print("Error cek ongkir: $e");
      if (mounted) {
        setState(() => _isLoadingOngkir = false);
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

  int get ongkosKirim => _layananDipilih?['harga'] ?? 0;
  int get pajak => ((subtotalProduk + ongkosKirim) * 0.11).round();
  int get totalPembayaran => subtotalProduk + ongkosKirim + pajak;

  String _formatRupiah(int number) {
    return 'Rp. ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _prosesBuatPesanan() async {
    if (_alamatDipilih == null || _alamatDipilih!.isEmpty) {
      _showSnackBar('Silakan pilih alamat pengiriman terlebih dahulu');
      return;
    }
    if (_ekspedisiDipilih == null || _layananDipilih == null) {
      _showSnackBar('Silakan pilih ekspedisi pengiriman');
      return;
    }
    if (_pembayaranDipilih == null) {
      _showSnackBar('Silakan pilih metode pembayaran');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _checkoutService.checkout(
        idAlamat: _alamatDipilih!['public_id'] ?? _alamatDipilih!['id_alamat'],
        idEkspedisi: _ekspedisiDipilih!['id_ekspedisi'],
        idLayananEkspedisi: _layananDipilih!['id_layanan_ekspedisi'],
        ongkosKirim: _layananDipilih!['harga'],
        catatan: _catatanController.text,
        idMetodePembayaran: _pembayaranDipilih!['id_metode_pembayaran'],
      );

      final data = result['data'];
      final midtransToken = data['midtrans_token'];
      final idPesanan = data['id_pesanan'];

      if (midtransToken != null && midtransToken.toString().isNotEmpty) {
        // TODO: integrasi Midtrans SDK
        print("Midtrans Token: $midtransToken");
      }

      if (mounted) {
        _showSnackBar('Pesanan berhasil dibuat! ID: $idPesanan');
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error checkout: $e");
      if (mounted) {
        _showSnackBar('Gagal membuat pesanan: ${e.toString()}');
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFAD510D)),
    );
  }

  Future<void> _pindahKePilihAlamat() async {
    final alamatBaruTerpilih = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PilihAlamatPage(alamatSekarang: _alamatDipilih),
      ),
    );

    if (alamatBaruTerpilih != null && alamatBaruTerpilih is Map<String, dynamic>) {
      setState(() {
        _alamatDipilih = alamatBaruTerpilih;
        _ekspedisiDipilih = null;
        _layananDipilih = null;
      });
      _cekOngkir();
    }
  }

  Future<void> _pindahKePilihPembayaran() async {
    final pembayaranBaru = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PilihPembayaranPage(
          pembayaranSekarang: _pembayaranDipilih,
          daftarMetode: _daftarMetode,
        ),
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFAD510D)))
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFAD510D),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Checkout',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ...widget.selectedProducts.map((item) => _buildCheckoutProductTile(item)),
                        const SizedBox(height: 10),

                        const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, color: Color(0xFFAD510D), size: 20),
                            SizedBox(width: 8),
                            Text('Rincian Pengiriman', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildAlamatBackendCard(),
                        const SizedBox(height: 16),

                        if (_isLoadingOngkir)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFFAD510D))),
                          )
                        else if (_daftarEkspedisi.isNotEmpty)
                          _buildPilihEkspedisiCard(),
                        const SizedBox(height: 16),

                        if (_isLoadingMetode)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFFAD510D))),
                          )
                        else
                          _buildPembayaranCard(),
                        const SizedBox(height: 16),

                        _buildCatatanField(),
                        const SizedBox(height: 16),

                        _buildNotaRincianCard(),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _prosesBuatPesanan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAD510D),
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Buat Pesanan', textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(item['subtitle'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatRupiah(item['price']), style: const TextStyle(color: Color(0xFFAD510D), fontWeight: FontWeight.bold)),
                    Text('Qty: ${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_alamatDipilih == null || _alamatDipilih!.isEmpty) {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFEEF3F4), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Belum ada alamat dipilih.", style: TextStyle(color: Colors.grey)),
            GestureDetector(
              onTap: _pindahKePilihAlamat,
              child: const Text('Pilih', style: TextStyle(color: Color(0xFFAD510D), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEEF3F4), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0x33AD510D), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _alamatDipilih!['label_alamat'] ?? 'Alamat',
                  style: const TextStyle(color: Color(0xFFAD510D), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: _pindahKePilihAlamat,
                child: const Text('Ubah', style: TextStyle(color: Color(0xFFAD510D), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_alamatDipilih!['nama_penerima'] ?? 'Penerima', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(_alamatDipilih!['alamat_lengkap'] ?? '-', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPilihEkspedisiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEEF3F4), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Color(0xFFAD510D), size: 18),
              SizedBox(width: 8),
              Text('Pilih Ekspedisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ..._daftarEkspedisi.map((ekspedisi) {
            final isEkspedisiSelected = _ekspedisiDipilih?['id_ekspedisi'] == ekspedisi['id_ekspedisi'];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isEkspedisiSelected ? const Color(0x33AD510D) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEkspedisiSelected ? const Color(0xFFAD510D) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ekspedisi['nama_ekspedisi'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...(ekspedisi['layanan'] as List).map((layanan) {
                        final isSelected = _layananDipilih?['id_layanan_ekspedisi'] == layanan['id_layanan_ekspedisi'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _ekspedisiDipilih = ekspedisi;
                              _layananDipilih = layanan;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFAD510D) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${layanan['nama_layanan']} (${layanan['durasi'] ?? '-'})',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatRupiah(layanan['harga'] ?? 0),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFFAD510D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPembayaranCard() {
    return Container(
      height: _pembayaranDipilih != null ? 140 : 60,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEEF3F4), borderRadius: BorderRadius.circular(20)),
      child: _pembayaranDipilih != null
          ? Row(
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
                      child: Icon(_pembayaranDipilih!['icon'] ?? Icons.payment_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_pembayaranDipilih!['nama'] ?? 'Metode Pembayaran',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(_pembayaranDipilih!['sub'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _pindahKePilihPembayaran,
                  child: const Text('Ubah', style: TextStyle(color: Color(0xFFAD510D), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          : GestureDetector(
              onTap: _pindahKePilihPembayaran,
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFFAD510D), size: 20),
                  SizedBox(width: 8),
                  Text('Pilih Metode Pembayaran',
                    style: TextStyle(color: Color(0xFFAD510D), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
    );
  }

  Widget _buildCatatanField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEEF3F4), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Contoh: Hati-hati, barang mudah pecah',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaRincianCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEEF3F4), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _notaRow('Subtotal', _formatRupiah(subtotalProduk)),
          const SizedBox(height: 10),
          _notaRow('Ongkos Kirim', _formatRupiah(ongkosKirim)),
          const SizedBox(height: 10),
          _notaRow('Pajak (11%)', _formatRupiah(pajak)),
          const Divider(height: 24, thickness: 0.5, color: Colors.grey),
          _notaRow('Total Pembayaran', _formatRupiah(totalPembayaran)),
        ],
      ),
    );
  }

  Widget _notaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
