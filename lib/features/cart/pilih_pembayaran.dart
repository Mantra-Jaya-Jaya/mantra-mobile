import 'package:flutter/material.dart';
import '../../core/widgets/base_header_widget.dart';
import '../orders/services/customer_order_service.dart';

class PilihPembayaranPage extends StatefulWidget {
  final Map<String, dynamic>? pembayaranSekarang;

  const PilihPembayaranPage({super.key, this.pembayaranSekarang});

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
    _pembayaranTerpilih = widget.pembayaranSekarang;

    // Jika sebelumnya sudah ada pilihan, sesuaikan status expand kategori utamanya
    if (_pembayaranTerpilih != null) {
      _kategoriExpanded = _pembayaranTerpilih!['kategori'];
    }
    _ambilDaftarMetode();
  }

  Future<void> _ambilDaftarMetode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final metodeData = await _orderService.GetMetodePembayaran();
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

    for (var item in _daftarMetode) {
      final kode = item['kode_metode'] ?? '';
      final nama = item['nama_metode'] ?? '';

      if (kode == 'cash') {
        children.add(
          _buildKategoriUtamaCard(
            idKategori: 'cash',
            nama: nama,
            sub: 'Bayar tunai langsung',
            icon: Icons.payments_outlined,
            hasDropdown: false,
            onTap: () {
              setState(() {
                _kategoriExpanded = 'cash';
                _pembayaranTerpilih = {
                  'kategori': 'cash',
                  'id_metode': 'cash',
                  'nama': nama,
                  'sub': 'Bayar tunai langsung',
                  'icon': Icons.payments_outlined,
                };
              });
            },
          ),
        );
      } else if (kode == 'va') {
        children.add(
          _buildKategoriUtamaCard(
            idKategori: 'va',
            nama: nama,
            sub: 'Format otomatis & dicek otomatis',
            icon: Icons.account_balance_rounded,
            hasDropdown: true,
            onTap: () {
              setState(() {
                _kategoriExpanded = _kategoriExpanded == 'va' ? null : 'va';
              });
            },
          ),
        );
        if (_kategoriExpanded == 'va') {
          children.add(
            _buildSubDropdownContainer(
              children: [
                _buildSubMetodeTile(
                  idKategori: 'va',
                  idMetode: 'va_bni',
                  nama: 'BNI Virtual Account',
                  sub: 'Dicek otomatis',
                ),
                _buildSubMetodeTile(
                  idKategori: 'va',
                  idMetode: 'va_bri',
                  nama: 'BRI Virtual Account',
                  sub: 'Dicek otomatis',
                ),
                _buildSubMetodeTile(
                  idKategori: 'va',
                  idMetode: 'va_mandiri',
                  nama: 'Mandiri Virtual Account',
                  sub: 'Dicek otomatis',
                ),
                _buildSubMetodeTile(
                  idKategori: 'va',
                  idMetode: 'va_bca',
                  nama: 'BCA Virtual Account',
                  sub: 'Dicek otomatis',
                ),
              ],
            ),
          );
        }
      } else if (kode == 'qris') {
        children.add(
          _buildKategoriUtamaCard(
            idKategori: 'qris',
            nama: nama,
            sub: 'Bayar instan pakai aplikasi bank',
            icon: Icons.qr_code_scanner_rounded,
            hasDropdown: false,
            onTap: () {
              setState(() {
                _kategoriExpanded = 'qris';
                _pembayaranTerpilih = {
                  'kategori': 'qris',
                  'id_metode': 'qris',
                  'nama': nama,
                  'sub': 'Scan kode QR untuk bayar',
                  'icon': Icons.qr_code_scanner_rounded,
                };
              });
            },
          ),
        );
      } else if (kode == 'cod') {
        children.add(
          _buildKategoriUtamaCard(
            idKategori: 'cod',
            nama: nama,
            sub: 'Bayar tunai langsung ke kurir saat barang sampai',
            icon: Icons.handshake_rounded,
            hasDropdown: false,
            onTap: () {
              setState(() {
                _kategoriExpanded = 'cod';
                _pembayaranTerpilih = {
                  'kategori': 'cod',
                  'id_metode': 'cod',
                  'nama': nama,
                  'sub': 'Bayar tunai di tempat',
                  'icon': Icons.handshake_rounded,
                };
              });
            },
          ),
        );
      } else {
        // Fallback untuk metode lain
        children.add(
          _buildKategoriUtamaCard(
            idKategori: kode,
            nama: nama,
            sub: 'Bayar dengan $nama',
            icon: Icons.payment_rounded,
            hasDropdown: false,
            onTap: () {
              setState(() {
                _kategoriExpanded = kode;
                _pembayaranTerpilih = {
                  'kategori': kode,
                  'id_metode': kode,
                  'nama': nama,
                  'sub': 'Bayar dengan $nama',
                  'icon': Icons.payment_rounded,
                };
              });
            },
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

  // Widget Pembuat Box Kategori Utama (Mantra-pay, VA, E-Wallet, QRIS, COD)
  Widget _buildKategoriUtamaCard({
    required String idKategori,
    required String nama,
    required String sub,
    required IconData icon,
    required bool hasDropdown,
    required VoidCallback onTap,
  }) {
    final isCategoryActive = _kategoriExpanded == idKategori;
    // Check apakah ini pembayaran final (untuk yang non-dropdown seperti Mantra-pay, QRIS, COD)
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFAD510D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
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
            // Indikator Kanan: Dropdown Arrow atau Checkbox Bulat
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

  // Container Pembungkus Dropdown anak-anaknya agar terlihat rapi mengelompok
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

  // Baris Pilihan Bank atau E-Wallet Spesifik di dalam dropdown
  Widget _buildSubMetodeTile({
    required String idKategori,
    required String idMetode,
    required String nama,
    required String sub,
  }) {
    final isChecked = _isMetodeChecked(idMetode);

    return InkWell(
      onTap: () {
        setState(() {
          _pembayaranTerpilih = {
            'kategori': idKategori,
            'id_metode': idMetode,
            'nama': nama,
            'sub': sub,
            // Tentukan icon kustom saat tampil kembali di halaman Checkout
            'icon': idKategori == 'va'
                ? Icons.account_balance_rounded
                : Icons.phone_android_rounded,
          };
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
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
            // Lingkaran Radio Button kecil penanda aktif
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
