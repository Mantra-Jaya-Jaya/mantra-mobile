import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/customer_checkout_service.dart';
import '../../core/widgets/base_header_widget.dart';
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
  bool _isLoadingOngkir = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  Map<String, dynamic>? _alamatDipilih;
  Map<String, dynamic>? _pembayaranDipilih;

  List<dynamic> _daftarEkspedisi = [];
  Map<String, dynamic>? _ekspedisiDipilih;
  Map<String, dynamic>? _layananDipilih;
  int? _ekspedisiTerbukaIndex;
  final TextEditingController _catatanController = TextEditingController();

  int _tipeKurir = 1; // 1 = internal, 2 = external
  bool _dalamRadius = false;
  bool _isLoadingRadius = false;

  @override
  void initState() {
    super.initState();
    _pembayaranDipilih = null;
    _ambilAlamatDariBackend();
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
            orElse: () => daftarAlamatDariBackend.isNotEmpty
                ? daftarAlamatDariBackend.first
                : {},
          );
          _isLoading = false;
        });
        if (_alamatDipilih != null && _alamatDipilih!.isNotEmpty) {
          _cekRadius();
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

  Future<void> _cekRadius() async {
    if (_alamatDipilih == null || _alamatDipilih!.isEmpty) return;
    setState(() => _isLoadingRadius = true);

    try {
      final response = await _checkoutService.cekRadius(
        idAlamat: _alamatDipilih!['public_id'] ?? _alamatDipilih!['id_alamat'],
      );
      if (mounted) {
        final data = response['data'];
        setState(() {
          _dalamRadius = data['within_radius'] ?? false;
          _isLoadingRadius = false;
        });
      }
    } catch (e) {
      print("Error cek radius: $e");
      if (mounted) {
        setState(() => _isLoadingRadius = false);
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

  List<Map<String, dynamic>> _layananEkspedisi(Map<String, dynamic> ekspedisi) {
    final rawList = (ekspedisi['layanan'] as List?) ?? [];
    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _hargaTermurah(List<Map<String, dynamic>> layananList) {
    int? hargaTerendah;
    for (final layanan in layananList) {
      final harga = layanan['harga'];
      final nilai = harga is num
          ? harga.toInt()
          : int.tryParse(harga?.toString() ?? '');
      if (nilai == null) continue;
      if (hargaTerendah == null || nilai < hargaTerendah) {
        hargaTerendah = nilai;
      }
    }
    return hargaTerendah;
  }

  void _pilihEkspedisi(Map<String, dynamic> ekspedisi) {
    final index = _daftarEkspedisi.indexWhere((item) {
      if (item is! Map) return false;
      final map = Map<String, dynamic>.from(item);
      return map['id_ekspedisi'] == ekspedisi['id_ekspedisi'];
    });
    final layananList = _layananEkspedisi(ekspedisi);

    setState(() {
      _ekspedisiDipilih = ekspedisi;
      _ekspedisiTerbukaIndex = index >= 0 ? index : null;
      _layananDipilih = layananList.length == 1 ? layananList.first : null;
    });
  }

  void _pilihLayanan(
    Map<String, dynamic> ekspedisi,
    Map<String, dynamic> layanan,
  ) {
    final index = _daftarEkspedisi.indexWhere((item) {
      if (item is! Map) return false;
      final map = Map<String, dynamic>.from(item);
      return map['id_ekspedisi'] == ekspedisi['id_ekspedisi'];
    });

    setState(() {
      _ekspedisiDipilih = ekspedisi;
      _ekspedisiTerbukaIndex = index >= 0 ? index : null;
      _layananDipilih = layanan;
    });
  }

  Widget _buildSelectedShipmentSummary() {
    if (_ekspedisiDipilih == null) {
      return const SizedBox.shrink();
    }

    final namaEkspedisi = _stringValue(
      _ekspedisiDipilih?['nama_ekspedisi'],
      fallback: '-',
    );
    final namaLayanan = _stringValue(
      _layananDipilih?['nama_layanan'],
      fallback: 'Pilih layanan',
    );
    final harga = _layananDipilih?['harga'];
    final hargaText = harga is num
        ? _formatRupiah(harga.toInt())
        : harga == null
        ? '-'
        : _formatRupiah(int.tryParse(harga.toString()) ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFAD510D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFAD510D).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping_outlined, color: Color(0xFFAD510D)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ekspedisi terpilih',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  namaEkspedisi,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(namaLayanan, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hargaText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFAD510D),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _ekspedisiDipilih = null;
                    _layananDipilih = null;
                    _ekspedisiTerbukaIndex = null;
                  });
                },
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAD510D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int get subtotalProduk {
    int total = 0;
    for (var item in widget.selectedProducts) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    return total;
  }

  int get ongkosKirim => _tipeKurir == 1 ? 0 : (_layananDipilih?['harga'] ?? 0);
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
    if (_tipeKurir == 2 &&
        (_ekspedisiDipilih == null || _layananDipilih == null)) {
      _showSnackBar('Silakan pilih ekspedisi pengiriman');
      return;
    }
    if (_tipeKurir == 1 && !_dalamRadius) {
      _showSnackBar(
        'Alamat Anda di luar jangkauan kurir toko, silakan pilih Kirim via Ekspedisi',
      );
      return;
    }
    if (_pembayaranDipilih == null) {
      _showSnackBar('Silakan pilih metode pembayaran');
      return;
    }

    setState(() => _isSubmitting = true);

    final items = widget.selectedProducts
        .map(
          (p) => {
            'id_spesifikasi_barang': p['id_spesifikasi_barang'] ?? p['id'],
            'qty': p['quantity'],
          },
        )
        .toList();

    try {
      final result = await _checkoutService.checkout(
        idAlamat: _alamatDipilih!['public_id'] ?? _alamatDipilih!['id_alamat'],
        items: items,
        idEkspedisi: _tipeKurir == 2
            ? _ekspedisiDipilih!['id_ekspedisi']
            : null,
        idLayananEkspedisi: _tipeKurir == 2
            ? _layananDipilih!['id_layanan_ekspedisi']
            : null,
        ongkosKirim: _tipeKurir == 2 ? _layananDipilih!['harga'] : 0,
        catatan: _catatanController.text,
        idMetodePembayaran: _pembayaranDipilih!['id_metode'],
        idTipeKurir: _tipeKurir,
      );

      final data = result['data'];
      final midtransToken = data['midtrans_token'];
      final idPesanan = data['id_pesanan'];

      if (midtransToken != null && midtransToken.toString().isNotEmpty) {
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
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFAD510D),
      ),
    );
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
        _ekspedisiDipilih = null;
        _layananDipilih = null;
        _ekspedisiTerbukaIndex = null;
        _tipeKurir = 1;
      });
      _cekRadius();
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
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ...widget.selectedProducts.map(
                          (item) => _buildCheckoutProductTile(item),
                        ),
                        const SizedBox(height: 10),

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

                        // Pilih Tipe Kurir
                        _buildPilihTipeKurir(),
                        const SizedBox(height: 16),

                        if (_tipeKurir == 2)
                          _isLoadingOngkir
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFAD510D),
                                    ),
                                  ),
                                )
                              : _daftarEkspedisi.isNotEmpty
                              ? _buildPilihEkspedisiCard()
                              : const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'Tidak ada ekspedisi tersedia untuk alamat ini',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                        const SizedBox(height: 16),
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

                        _buildPembayaranCard(),
                        const SizedBox(height: 16),

                        _buildCatatanField(),
                        const SizedBox(height: 16),

                        _buildNotaRincianCard(),
                        const SizedBox(height: 24),
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
                  onPressed: _isSubmitting ? null : _prosesBuatPesanan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
                  item['subtitle'] ?? '',
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

  Widget _buildPilihTipeKurir() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFFAD510D),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Pilih Kurir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                _tipeKurir = 1;
                _ekspedisiDipilih = null;
                _layananDipilih = null;
              });
              _cekRadius();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _tipeKurir == 1 ? const Color(0x33AD510D) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _tipeKurir == 1
                      ? const Color(0xFFAD510D)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: 1,
                    groupValue: _tipeKurir,
                    activeColor: const Color(0xFFAD510D),
                    onChanged: (v) {
                      setState(() {
                        _tipeKurir = v!;
                        _ekspedisiDipilih = null;
                        _layananDipilih = null;
                        _ekspedisiTerbukaIndex = null;
                      });
                      _cekRadius();
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Antar Kurir Toko',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_isLoadingRadius)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_dalamRadius)
                          const Text(
                            'Gratis · Dalam jangkauan',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          )
                        else
                          const Text(
                            'Di luar jangkauan',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _tipeKurir = 2;
              });
              _cekOngkir();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _tipeKurir == 2 ? const Color(0x33AD510D) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _tipeKurir == 2
                      ? const Color(0xFFAD510D)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: 2,
                    groupValue: _tipeKurir,
                    activeColor: const Color(0xFFAD510D),
                    onChanged: (v) {
                      setState(() {
                        _tipeKurir = v!;
                      });
                      _cekOngkir();
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Kirim via Ekspedisi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPilihEkspedisiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFFAD510D),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Pilih Ekspedisi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSelectedShipmentSummary(),
          if (_ekspedisiDipilih != null) const SizedBox(height: 12),
          ...List.generate(_daftarEkspedisi.length, (i) {
            final ekspedisi = Map<String, dynamic>.from(
              _daftarEkspedisi[i] as Map,
            );
            final layananList = _layananEkspedisi(ekspedisi);
            final isSelectedCourier =
                _ekspedisiDipilih?['id_ekspedisi'] == ekspedisi['id_ekspedisi'];
            final isExpanded = _ekspedisiTerbukaIndex == i || isSelectedCourier;
            final lowestPrice = _hargaTermurah(layananList);
            final summaryPrice = lowestPrice != null
                ? _formatRupiah(lowestPrice)
                : 'Layanan belum tersedia';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelectedCourier
                      ? const Color(0xFFAD510D)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _pilihEkspedisi(ekspedisi),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ekspedisi['nama_ekspedisi'] ?? 'Ekspedisi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  layananList.isEmpty
                                      ? 'Belum ada layanan'
                                      : '${layananList.length} layanan • mulai $summaryPrice',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: isSelectedCourier
                                ? const Color(0xFFAD510D)
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: layananList.map((layanan) {
                          final selected =
                              _layananDipilih?['id_layanan_ekspedisi'] ==
                              layanan['id_layanan_ekspedisi'];
                          return InkWell(
                            onTap: () => _pilihLayanan(ekspedisi, layanan),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0x33AD510D)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFAD510D)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          layanan['nama_layanan'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (layanan['estimasi'] != null)
                                          Text(
                                            'Estimasi ${layanan['estimasi']}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(layanan['harga'] ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFFAD510D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(dynamic icon) {
    if (icon is String) {
      if (icon.startsWith('http')) {
        return Image.network(icon, width: 20, height: 20, color: Colors.white);
      }
      const iconMap = {
        'phone_android_rounded': Icons.phone_android_rounded,
        'payment_rounded': Icons.payment_rounded,
        'account_balance_rounded': Icons.account_balance_rounded,
        'payments_outlined': Icons.payments_outlined,
        'package_outlined': Icons.local_shipping_outlined,
        'qr_code_scanner': Icons.qr_code_scanner,
      };
      final mapped = iconMap[icon];
      if (mapped != null) {
        return Icon(mapped, color: Colors.white, size: 20);
      }
    }
    return const Icon(Icons.payment_rounded, color: Colors.white, size: 20);
  }

  Widget _buildPembayaranCard() {
    return Container(
      height: _pembayaranDipilih != null ? 140 : 60,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
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
                      child: _buildPaymentIcon(_pembayaranDipilih!['icon']),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _pembayaranDipilih!['nama'] ?? 'Metode Pembayaran',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _pembayaranDipilih!['sub'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
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
            )
          : GestureDetector(
              onTap: _pindahKePilihPembayaran,
              child: const Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFFAD510D),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(
                      color: Color(0xFFAD510D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCatatanField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
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
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
