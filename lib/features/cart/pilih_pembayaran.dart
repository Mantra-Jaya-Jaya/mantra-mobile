// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/widgets/base_header_widget.dart';
import '../../core/widgets/payment_icon_widget.dart';
import '../orders/services/customer_order_service.dart';

class PilihPembayaranPage extends StatefulWidget {
  final Map<String, dynamic>? pembayaranSekarang;
  final bool isEksternal;

  const PilihPembayaranPage({super.key, this.pembayaranSekarang, this.isEksternal = false});

  @override
  State<PilihPembayaranPage> createState() => _PilihPembayaranPageState();
}

class _PilihPembayaranPageState extends State<PilihPembayaranPage> {
  final CustomerOrderService _orderService = CustomerOrderService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _daftarMetode = [];

  // Variabel untuk melacak kategori utama mana yang sedang di-expand (membentang)
  String? _kategoriExpanded;

  // Variabel penampung sub-pilihan atau pilihan final
  Map<String, dynamic>? _pembayaranTerpilih;

  @override
  void initState() {
    super.initState();
    _pembayaranTerpilih = _normalizePaymentSelection(widget.pembayaranSekarang);

    // Jika sebelumnya sudah ada pilihan, sesuaikan status expand kategori utamanya
    if (_pembayaranTerpilih != null) {
      _kategoriExpanded = _pembayaranTerpilih!['kategori'];
    }
    _ambilDaftarMetode();
  }

  Map<String, dynamic>? _normalizePaymentSelection(
    Map<String, dynamic>? selection,
  ) {
    if (selection == null) return null;

    final rawCode = (selection['kategori'] ?? selection['id_metode'] ?? '')
        .toString()
        .toLowerCase();

    if (rawCode != 'cash') return selection;

    return {
      ...selection,
      'kategori': 'cod',
      'id_metode': 'cod',
      'nama': 'COD',
      'sub': 'Bayar ke kurir saat barang sampai',
    };
  }

  Future<void> _ambilDaftarMetode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final metodeData = await _orderService.getMetodePembayaran();
      
      // Hapus metode COD (atau cash) kalau kurir eksternal
      if (widget.isEksternal) {
        metodeData.removeWhere((item) {
          final k = (item['kode_metode'] ?? '').toString().toLowerCase();
          return k == 'cod' || k == 'cash';
        });
      }

      setState(() {
        _daftarMetode = metodeData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Gagal memuat metode pembayaran.";
      });
    }
  }

  // Fungsi pembantu untuk mendeteksi apakah item ini yang sedang aktif dicentang
  bool _isMetodeChecked(String idMetode) {
    return _pembayaranTerpilih?['id_metode'] == idMetode;
  }

  Widget _buildDynamicMetodeList() {
    List<Widget> children = [];
    List<Map<String, dynamic>> listVirtualAccount = [];

    // 1. Kumpulkan semua data bank ber-kode 'va' ke dalam list khusus VA
    for (var item in _daftarMetode) {
      if (item['kode_metode'] == 'va') {
        listVirtualAccount.add(item);
      }
    }

    // 2. Render menu utama non-dropdown (Cash, QRIS, COD) - Tetap normal
    for (var item in _daftarMetode) {
      final kode = (item['kode_metode'] ?? '').toString();
      final nama = item['nama_metode'] ?? '';
      final iconUrl = item['icon'] ?? '';

      if (kode == 'cash') {
        continue;
      }

      if (kode == 'qris' || kode == 'cod') {
        children.add(
          _buildKategoriUtamaCard(
            idKategori: kode,
            nama: nama,
            sub: kode == 'cash'
                ? 'Bayar tunai langsung'
                : (kode == 'qris'
                      ? 'Scan kode QR untuk bayar'
                      : 'Bayar ke kurir saat barang sampai'),
            iconUrl: iconUrl,
            hasDropdown: false,
            onTap: () {
              setState(() {
                _kategoriExpanded = kode;
                _pembayaranTerpilih = {
                  'kategori': kode,
                  'id_metode': kode,
                  'id_metode_pembayaran': item['id_metode_pembayaran']?.toString(),
                  'nama': nama,
                  'sub': kode == 'cash'
                      ? 'Bayar tunai langsung'
                      : (kode == 'qris' ? 'Scan kode QR' : 'Bayar di tempat'),
                  'icon': iconUrl,
                };
              });
            },
          ),
        );
      }
    }

    // 3. AMAN & TEPAT: Render SATU grup dropdown Virtual Account saja jika datanya ada
    if (listVirtualAccount.isNotEmpty) {
      final isVaExpanded =
          _kategoriExpanded == 'group_va' || _kategoriExpanded == 'va';

      children.add(
        _buildKategoriUtamaCard(
          idKategori: 'group_va',
          nama: 'Virtual Account',
          sub: 'Format otomatis & dicek otomatis',
          iconUrl: 'phone_android_rounded',
          hasDropdown: true,
          onTap: () {
            setState(() {
              _kategoriExpanded = isVaExpanded ? null : 'group_va';
            });
          },
        ),
      );

      // Jika dropdown dibuka, bongkar seluruh isi bank di dalamnya secara vertikal
      if (isVaExpanded) {
        children.add(
          _buildSubDropdownContainer(
            children: listVirtualAccount.map((bank) {
              final namaBank = bank['nama_metode'] ?? '';
              final iconBank = bank['icon'] ?? '';

              // Mapping manual idMetode untuk frontend agar sinkron dengan sistem checkout lamamu
              String idMetodeFrontend = 'va';
              final namaLower = namaBank.toLowerCase();
              if (namaLower.contains('bni')) idMetodeFrontend = 'va_bni';
              if (namaLower.contains('bca')) idMetodeFrontend = 'va_bca';
              if (namaLower.contains('mandiri')) {
                idMetodeFrontend = 'va_mandiri';
              }
              if (namaLower.contains('bri')) idMetodeFrontend = 'va_bri';

              return _buildSubMetodeTile(
                idKategori: 'va',
                idMetode: idMetodeFrontend,
                idMetodePembayaran: bank['id_metode_pembayaran']?.toString(),
                nama: namaBank,
                sub: 'Dicek otomatis',
                iconUrl: iconBank,
              );
            }).toList(),
          ),
        );
      }
    }

    return ListView(padding: const EdgeInsets.all(20), children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Metode Pembayaran',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFAD510D),
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _daftarMetode.isEmpty
                  ? const Center(
                      child: Text('Tidak ada metode pembayaran aktif.'),
                    )
                  : _buildDynamicMetodeList(),
            ),

            // Tombol Konfirmasi Pembayaran di Bagian Bawah
            if (_pembayaranTerpilih != null)
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Mengembalikan data pembayaran lengkap ke halaman Checkout
                    Navigator.pop(context, _pembayaranTerpilih);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Konfirmasi Pembayaran',
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
    );
  }

  // Widget Pembuat Box Kategori Utama (Telah diubah menggunakan String iconUrl dari internet)
  Widget _buildKategoriUtamaCard({
    required String idKategori,
    required String nama,
    required String sub,
    required String iconUrl, // Bisa jadi nama icon (package_outlined) atau URL gambar
    required bool hasDropdown,
    required VoidCallback onTap,
  }) {
    final isCategoryActive =
        _kategoriExpanded == idKategori ||
        (idKategori == 'group_va' &&
            (_kategoriExpanded == 'group_va' || _kategoriExpanded == 'va'));

    final isChecked =
        _pembayaranTerpilih?['kategori'] == idKategori && !hasDropdown;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isCategoryActive || isChecked)
                ? const Color(0xFFAD510D)
                : Colors.grey.shade200,
            width: (isCategoryActive || isChecked) ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: PaymentIconWidget(
                iconValue: iconUrl,
                paymentName: nama,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (hasDropdown)
              Icon(
                isCategoryActive
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: isCategoryActive ? const Color(0xFFAD510D) : Colors.grey,
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? const Color(0xFFAD510D) : Colors.white,
                  border: Border.all(
                    color: isChecked
                        ? const Color(0xFFAD510D)
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubDropdownContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 4, left: 10, right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  // Widget Baris Pilihan Bank (Telah diubah menggunakan String iconUrl dari internet)
  Widget _buildSubMetodeTile({
    required String idKategori,
    required String idMetode,
    required String? idMetodePembayaran,
    required String nama,
    required String sub,
    required String iconUrl,
  }) {
    final isChecked = _isMetodeChecked(idMetode);

    return InkWell(
      onTap: () {
        setState(() {
          _pembayaranTerpilih = {
            'kategori': idKategori,
            'id_metode': idMetode,
            'id_metode_pembayaran': idMetodePembayaran,
            'nama': nama,
            'sub': sub,
            'icon': iconUrl,
          };
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            // Tampilkan logo bank kecil secara dinamis di dalam dropdown anak
            Container(
              padding: const EdgeInsets.all(4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: PaymentIconWidget(
                iconValue: iconUrl,
                paymentName: nama,
                size: 24,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: TextStyle(
                      fontWeight: isChecked
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? const Color(0xFFAD510D) : Colors.white,
                border: Border.all(
                  color: isChecked
                      ? const Color(0xFFAD510D)
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
