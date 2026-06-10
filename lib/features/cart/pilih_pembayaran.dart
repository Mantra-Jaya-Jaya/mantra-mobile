import 'package:flutter/material.dart';
import '../../core/models/metode_pembayaran_model.dart';

class PilihPembayaranPage extends StatefulWidget {
  final Map<String, dynamic>? pembayaranSekarang;
  final List<MetodePembayaran> daftarMetode;

  const PilihPembayaranPage({
    super.key,
    this.pembayaranSekarang,
    required this.daftarMetode,
  });

  @override
  State<PilihPembayaranPage> createState() => _PilihPembayaranPageState();
}

class _PilihPembayaranPageState extends State<PilihPembayaranPage> {
  String? _kategoriExpanded;
  Map<String, dynamic>? _pembayaranTerpilih;

  @override
  void initState() {
    super.initState();
    _pembayaranTerpilih = widget.pembayaranSekarang;
    if (_pembayaranTerpilih != null) {
      _kategoriExpanded = _pembayaranTerpilih!['kategori'];
    }
  }

  List<MetodePembayaran> _getByCategory(String prefix) {
    return widget.daftarMetode.where((m) =>
      m.kodeMetode.startsWith(prefix)
    ).toList();
  }

  bool _isMetodeChecked(int id) {
    return _pembayaranTerpilih?['id_metode_pembayaran'] == id;
  }

  IconData _iconForMetode(String kodeMetode) {
    if (kodeMetode == 'mantrapay') return Icons.wallet_rounded;
    if (kodeMetode.startsWith('va_')) return Icons.account_balance_rounded;
    if (kodeMetode.startsWith('ew_')) return Icons.phone_android_rounded;
    if (kodeMetode == 'qris') return Icons.qr_code_scanner_rounded;
    if (kodeMetode == 'cod') return Icons.handshake_rounded;
    return Icons.payment_rounded;
  }

  String _subtitleForMetode(String kodeMetode) {
    if (kodeMetode == 'mantrapay') return 'Saldo internal';
    if (kodeMetode == 'qris') return 'Scan QR untuk bayar';
    if (kodeMetode == 'cod') return 'Bayar tunai di tempat';
    if (kodeMetode.startsWith('va_')) return 'Transfer bank otomatis';
    if (kodeMetode.startsWith('ew_')) return 'Bayar via e-wallet';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final mantrapayList = _getByCategory('mantrapay');
    final vaList = _getByCategory('va_');
    final ewalletList = _getByCategory('ew_');
    final qrisList = _getByCategory('qris');
    final codList = _getByCategory('cod');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFAD510D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (mantrapayList.isNotEmpty)
                    _buildKategoriUtamaCard(
                      idKategori: 'mantrapay',
                      nama: 'Mantra-pay',
                      sub: 'Saldo internal',
                      icon: Icons.wallet_rounded,
                      hasDropdown: false,
                      metode: mantrapayList.first,
                    ),

                  if (vaList.isNotEmpty)
                    _buildKategoriUtamaCard(
                      idKategori: 'va',
                      nama: 'Transfer Bank (VA)',
                      sub: 'Format otomatis & dicek otomatis',
                      icon: Icons.account_balance_rounded,
                      hasDropdown: true,
                    ),
                  if (_kategoriExpanded == 'va')
                    _buildSubDropdownContainer(
                      children: vaList.map((m) =>
                        _buildSubMetodeTile(metode: m)
                      ).toList(),
                    ),

                  if (ewalletList.isNotEmpty)
                    _buildKategoriUtamaCard(
                      idKategori: 'ewallet',
                      nama: 'E-Wallet',
                      sub: 'DANA, ShopeePay, OVO, dll',
                      icon: Icons.phone_android_rounded,
                      hasDropdown: true,
                    ),
                  if (_kategoriExpanded == 'ewallet')
                    _buildSubDropdownContainer(
                      children: ewalletList.map((m) =>
                        _buildSubMetodeTile(metode: m)
                      ).toList(),
                    ),

                  if (qrisList.isNotEmpty)
                    _buildKategoriUtamaCard(
                      idKategori: 'qris',
                      nama: 'QRIS',
                      sub: 'Bayar instan pakai QR',
                      icon: Icons.qr_code_scanner_rounded,
                      hasDropdown: false,
                      metode: qrisList.first,
                    ),

                  if (codList.isNotEmpty)
                    _buildKategoriUtamaCard(
                      idKategori: 'cod',
                      nama: 'Cash on Delivery (COD)',
                      sub: 'Bayar tunai di tempat',
                      icon: Icons.handshake_rounded,
                      hasDropdown: false,
                      metode: codList.first,
                    ),
                ],
              ),
            ),

            if (_pembayaranTerpilih != null)
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _pembayaranTerpilih);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD510D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Konfirmasi Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriUtamaCard({
    required String idKategori,
    required String nama,
    required String sub,
    required IconData icon,
    required bool hasDropdown,
    MetodePembayaran? metode,
  }) {
    final isCategoryActive = _kategoriExpanded == idKategori;
    final isChecked = _pembayaranTerpilih?['kategori'] == idKategori && !hasDropdown;

    return GestureDetector(
      onTap: () {
        if (hasDropdown) {
          setState(() {
            _kategoriExpanded = _kategoriExpanded == idKategori ? null : idKategori;
          });
        } else if (metode != null) {
          setState(() {
            _kategoriExpanded = idKategori;
            _pembayaranTerpilih = {
              'kategori': idKategori,
              'id_metode_pembayaran': metode.idMetodePembayaran,
              'nama': metode.namaMetode,
              'sub': _subtitleForMetode(metode.kodeMetode),
              'icon': _iconForMetode(metode.kodeMetode),
            };
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isCategoryActive || isChecked) ? const Color(0xFFAD510D) : Colors.grey.shade200,
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
                  Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (hasDropdown)
              Icon(
                isCategoryActive ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
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
                    color: isChecked ? const Color(0xFFAD510D) : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
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

  Widget _buildSubMetodeTile({required MetodePembayaran metode}) {
    final isChecked = _isMetodeChecked(metode.idMetodePembayaran);

    return InkWell(
      onTap: () {
        setState(() {
          _pembayaranTerpilih = {
            'kategori': metode.kodeMetode.startsWith('va_') ? 'va' : 'ewallet',
            'id_metode_pembayaran': metode.idMetodePembayaran,
            'nama': metode.namaMetode,
            'sub': _subtitleForMetode(metode.kodeMetode),
            'icon': metode.kodeMetode.startsWith('va_')
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
                  Text(metode.namaMetode, style: TextStyle(fontWeight: isChecked ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(_subtitleForMetode(metode.kodeMetode), style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
                  color: isChecked ? const Color(0xFFAD510D) : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isChecked ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }
}
