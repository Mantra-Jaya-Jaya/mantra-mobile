import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/models/payment_model.dart';
import '../../core/services/payment_service.dart';
import 'metode_pembayaran.dart';

// ── Design Tokens ──────────────────────────────────────────
class _K {
  static const orange      = Color(0xFFE8621A);
  static const orangeLight = Color(0xFFFFF0E8);
  static const orangeDark  = Color(0xFFC04D0F);
  static const black       = Color(0xFF1A1A1A);
  static const grey900     = Color(0xFF2D2D2D);
  static const grey600     = Color(0xFF757575);
  static const grey300     = Color(0xFFE0E0E0);
  static const grey100     = Color(0xFFF5F5F5);
  static const white       = Color(0xFFFFFFFF);
}

class KasirPosScreen extends StatefulWidget {
  final int idPesanan;
  const KasirPosScreen({super.key, required this.idPesanan});

  @override
  State<KasirPosScreen> createState() => _KasirPosScreenState();
}

class _KasirPosScreenState extends State<KasirPosScreen> {
  final _service = PaymentService();
  final _searchCtrl = TextEditingController();
  final List<ItemKeranjang> _keranjang = [];
  bool _loadingUpdate = false;
  bool _loadingCari = false;
  bool _showHasil = false;
  bool _scannerOpen = false;
  List<HasilCariProduk> _hasilCari = [];
  MobileScannerController? _scannerCtrl;

  late int _currentIdPesanan;

  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int get _subtotal => _keranjang.fold(0, (sum, i) => sum + i.subtotal);
  int get _total => _subtotal;

  @override
  void initState() {
    super.initState();
    _currentIdPesanan = widget.idPesanan;
  }

  void _resetTransaksi() {
    setState(() {
      _currentIdPesanan = 0;
      _keranjang.clear();
      _searchCtrl.clear();
      _hasilCari = [];
      _showHasil = false;
    });
  }

  Future<void> _cari(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _hasilCari = []; _showHasil = false; });
      return;
    }
    setState(() { _loadingCari = true; _showHasil = true; });
    try {
      final hasil = await _service.cariProduk(q.trim());
      setState(() => _hasilCari = hasil);
    } catch (e) {
      setState(() => _hasilCari = []);
      if (mounted) _snackError('Produk tidak ditemukan');
    } finally {
      setState(() => _loadingCari = false);
    }
  }

  Future<void> _tambahItem(HasilCariProduk produk, VarianProduk varian) async {
    if (varian.stok <= 0) { _snackError('Stok habis'); return; }

    final idx = _keranjang.indexWhere((i) => i.idSpesifikasiBarang == varian.idSpesifikasiBarang);

    setState(() {
      _loadingUpdate = true;
      _showHasil = false;
      _searchCtrl.clear();
      _hasilCari = [];
    });

    try {
      if (idx >= 0) {
        final newQty = _keranjang[idx].jumlah + 1;
        final newId = await _service.updateQuantityItem(idPesanan: _currentIdPesanan, idSpesifikasiBarang: varian.idSpesifikasiBarang, jumlah: newQty);
        setState(() { _currentIdPesanan = newId; _keranjang[idx].jumlah = newQty; });
      } else {
        final newId = await _service.updateQuantityItem(idPesanan: _currentIdPesanan, idSpesifikasiBarang: varian.idSpesifikasiBarang, jumlah: 1);
        setState(() {
          _currentIdPesanan = newId;
          _keranjang.add(ItemKeranjang(
            idPesanan: _currentIdPesanan,
            idSpesifikasiBarang: varian.idSpesifikasiBarang,
            namaProduk: produk.namaBarang,
            labelVarian: varian.label,
            hargaSatuan: varian.hargaDiskon > 0 ? varian.hargaDiskon : varian.hargaBarang,
            jumlah: 1,
          ));
        });
      }
    } catch (e) {
      _snackError('Gagal menambahkan item: $e');
    } finally {
      setState(() => _loadingUpdate = false);
    }
  }

  Future<void> _updateQty(int idx, int delta) async {
    final item = _keranjang[idx];
    final newQty = item.jumlah + delta;
    setState(() => _loadingUpdate = true);
    try {
      final newId = await _service.updateQuantityItem(idPesanan: _currentIdPesanan, idSpesifikasiBarang: item.idSpesifikasiBarang, jumlah: newQty);
      setState(() {
        _currentIdPesanan = newId;
        if (newQty <= 0) {
          _keranjang.removeAt(idx);
          if (_keranjang.isEmpty) _currentIdPesanan = 0;
        } else {
          _keranjang[idx].jumlah = newQty;
        }
      });
    } catch (e) {
      _snackError('Gagal update: $e');
    } finally {
      setState(() => _loadingUpdate = false);
    }
  }

  void _bukaScanner() {
    _scannerCtrl = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, facing: CameraFacing.back);
    setState(() => _scannerOpen = true);
  }

  void _tutupScanner() {
    _scannerCtrl?.dispose();
    _scannerCtrl = null;
    setState(() => _scannerOpen = false);
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    HapticFeedback.mediumImpact();
    _tutupScanner();
    _cari(barcode!.rawValue!);
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: Color(0xFFAF510C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scannerCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _K.grey100,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              if (_scannerOpen) _buildEmbeddedScanner(),
              if (_showHasil) _buildHasilCari(),
              Expanded(
                child: _keranjang.isEmpty ? _buildEmptyState() : _buildKeranjang(),
              ),
              if (_keranjang.isNotEmpty) _buildFooter(),
            ],
          ),
          if (_loadingUpdate)
            Container(
              color: Colors.black.withOpacity(0.18),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFAF510C)),
              ),
            ),
        ],
      ),
    );
  }

//App Bar
PreferredSizeWidget _buildAppBar() {
  return AppBar(
    backgroundColor: const Color(0xFFAF510C), // Warna solid
    elevation: 0,
    automaticallyImplyLeading: false, // Menghilangkan tombol back
    titleSpacing: 16, // Memberi jarak yang pas dari kiri
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Pesanan",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 18, // Ditingkatkan sedikit
          ),
        ),
      ],
    ),
    // Menambahkan shape: null atau zero untuk memastikan tidak ada rounded di bawah
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    ),
  );
}

  // ── Search Bar ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFAF510C),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(color: Color(0xFFAF510C).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: _cari,
                style: const TextStyle(fontSize: 14, color: _K.black),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau kode barang…',
                  hintStyle: TextStyle(color: _K.grey600.withOpacity(0.7), fontSize: 14),
                  prefixIcon: _loadingCari
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _K.orange)),
                        )
                      : Icon(Icons.search_rounded, color: _K.grey600, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _bukaScanner,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _K.orangeDark,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hasil Cari ─────────────────────────────────────────
  Widget _buildHasilCari() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: _K.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _hasilCari.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Produk tidak ditemukan', style: TextStyle(color: _K.grey600))),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _hasilCari.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _K.grey300),
                itemBuilder: (context, i) => _buildProdukTile(_hasilCari[i]),
              ),
      ),
    );
  }

  Widget _buildProdukTile(HasilCariProduk produk) {
    final punya1Varian = produk.varian.length == 1;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              (produk.gambarBarang != null && produk.gambarBarang!.isNotEmpty)
              ? Image.network(
                  produk.gambarBarang!,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  // Kalau link fotonya rusak, balikin jadi icon kardus
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 38,
                    height: 38,
                    color: _K.orangeLight,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: _K.orange,
                      size: 20,
                    ),
                  ),
                )
              : Container(
                  width: 38,
                  height: 38,
                  color: _K.orangeLight,
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: _K.orange,
                    size: 20,
                  ),
                ),
        ),
        title: Text(produk.namaBarang,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _K.black)),
        subtitle: Text('${produk.varian.length} varian',
            style: const TextStyle(fontSize: 12, color: _K.grey600)),
        initiallyExpanded: punya1Varian,
        onExpansionChanged: punya1Varian ? (_) => _tambahItem(produk, produk.varian.first) : null,
        childrenPadding: const EdgeInsets.only(bottom: 6),
        children: produk.varian.map((v) {
          final harga = v.hargaDiskon > 0 ? v.hargaDiskon : v.hargaBarang;
          return InkWell(
            onTap: () => _tambahItem(produk, v),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 46),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: _K.grey900)),
                        const SizedBox(height: 2),
                        Text(_fmt.format(harga), style: const TextStyle(color: _K.orange, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _K.orange, borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 2),
                      Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: _K.orangeLight, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_cart_outlined, color: _K.orange, size: 42),
          ),
          const SizedBox(height: 16),
          const Text('Keranjang Kosong', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _K.black)),
          const SizedBox(height: 6),
          Text('Cari barang atau scan barcode untuk\nmenambahkan ke keranjang',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _K.grey600, height: 1.5)),
        ],
      ),
    );
  }

  // ── Keranjang List ─────────────────────────────────────
  Widget _buildKeranjang() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      itemCount: _keranjang.length,
      itemBuilder: (context, i) {
        final item = _keranjang[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _K.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon / nomor urut
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _K.orangeLight, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: _K.orange, fontSize: 15)),
                ),
                const SizedBox(width: 12),
                // Nama & label varian
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaProduk,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _K.black),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.labelVarian,
                          style: const TextStyle(fontSize: 12, color: _K.grey600)),
                      const SizedBox(height: 4),
                      Text(_fmt.format(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _K.orange)),
                    ],
                  ),
                ),
                // Qty control
                Container(
                  decoration: BoxDecoration(
                    color: _K.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _K.grey300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _qtyButton(Icons.remove_rounded, () => _updateQty(i, -1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('${item.jumlah}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _K.black)),
                      ),
                      _qtyButton(Icons.add_rounded, () => _updateQty(i, 1), isAdd: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: isAdd ? _K.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: isAdd ? Colors.white : _K.grey900),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────
  Widget _buildFooter() {
  final itemCount = _keranjang.fold(0, (sum, i) => sum + i.jumlah);
  return Container(
    margin: const EdgeInsets.only(bottom: 10), // Jarak dari navbar
    decoration: BoxDecoration(
      color: Colors.white, // Latar belakang area pembayaran jadi putih
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2)),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _footerChip(Icons.shopping_bag_outlined, '$itemCount item'),
            const SizedBox(width: 8),
            _footerChip(Icons.layers_outlined, '${_keranjang.length} produk'),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Total', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                Text(_fmt.format(_total),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF1A1A1A), letterSpacing: -0.5)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Tombol Oranye
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _kePembayaran,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAF510C), // Warna Oranye AppBar
              foregroundColor: Colors.white, // Teks putih
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_rounded, size: 20),
                SizedBox(width: 8),
                Text('Pilih Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _footerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _K.orangeLight, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _K.orange),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _K.orange)),
        ],
      ),
    );
  }

  void _kePembayaran() async {
    print("KasirPosScreen mengirim ID Pesanan = $_currentIdPesanan");

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetodePembayaranScreen(
          idPesanan: _currentIdPesanan,
          totalAkhir: _total,
          keranjang: _keranjang,
        ),
      ),
    );

    _resetTransaksi();
  }

  Widget _buildEmbeddedScanner() {
    return Container(
      height: 220, // 🚀 Tingginya pas, gak menuhin layar
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 📷 View Kamera
            MobileScanner(
              controller: _scannerCtrl,
              onDetect: _onBarcodeDetected,
            ),

            // ⬛ Overlay Gelap di luar area scan
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  // 🚀 KOTAK SCANNER: Dibuat pipih & lebar khusus buat Barcode Batang!
                  Center(
                    child: Container(
                      width: 280, // Lebar
                      height: 100, // Pendek
                      decoration: BoxDecoration(
                        color: Colors.red, // Warna bebas, yang penting kepotong
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🎯 Bingkai Putih & Tombol
            Center(
              child: Container(
                width: 280,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // 💡 Tombol Senter & Tutup (Mirip referensi desain lu)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _scannerCtrl?.toggleTorch(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flashlight_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _tutupScanner,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
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
}