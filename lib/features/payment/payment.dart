// ============================================================
// screens/kasir_pos_screen.dart
// ============================================================
//
// Layar utama kasir POS:
//  - Kosong saat pertama dibuka (hanya search bar + tombol scan)
//  - Cari barang → tampil hasil → klik varian → masuk keranjang
//  - Scan barcode → langsung tambah ke keranjang
//  - Keranjang terisi → tampil total + tombol "Pilih Metode Pembayaran"
//
// Dependency pubspec.yaml yang wajib ada:
//   mobile_scanner: ^5.x.x        (scan barcode/QR)
//   intl: ^0.19.x                 (format angka rupiah)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/models/payment_model.dart';
import '../../core/services/payment_service.dart';
import 'metode_pembayaran.dart';

class KasirPosScreen extends StatefulWidget {
  /// idPesanan aktif yang sedang dibuat (bisa dari halaman sebelumnya)
  final int idPesanan;

  const KasirPosScreen({super.key, required this.idPesanan});

  @override
  State<KasirPosScreen> createState() => _KasirPosScreenState();
}

class _KasirPosScreenState extends State<KasirPosScreen> {
  // ── Service ──────────────────────────────────────────────
  final _service = PaymentService();

  // ── Search ───────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<HasilCariProduk> _hasilCari = [];
  bool _loadingCari = false;
  bool _showHasil = false;

  // ── Keranjang ────────────────────────────────────────────
  final List<ItemKeranjang> _keranjang = [];
  bool _loadingUpdate = false;

  // ── Scan ─────────────────────────────────────────────────
  bool _scannerOpen = false;
  MobileScannerController? _scannerCtrl;

  // ── Helpers ──────────────────────────────────────────────
  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int get _subtotal => _keranjang.fold(0, (sum, i) => sum + i.subtotal);
  int get _pajak => (_subtotal * 0.11).round();
  int get _total => _subtotal + _pajak;

  // ── Search ───────────────────────────────────────────────
  Future<void> _cari(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _hasilCari = [];
        _showHasil = false;
      });
      return;
    }

    setState(() {
      _loadingCari = true;
      _showHasil = true;
    });

    try {
      final hasil = await _service.cariProduk(q.trim());
      setState(() => _hasilCari = hasil);
    } catch (e) {
      setState(() => _hasilCari = []);
      if (mounted) {
        _snackError('Produk tidak ditemukan');
      }
    } finally {
      setState(() => _loadingCari = false);
    }
  }

  // ── Tambah ke keranjang ──────────────────────────────────
  Future<void> _tambahItem(HasilCariProduk produk, VarianProduk varian) async {
    // Cek stok
    if (varian.stok <= 0) {
      _snackError('Stok habis');
      return;
    }

    // Cek apakah item sudah ada di keranjang
    final idx = _keranjang.indexWhere(
      (i) => i.idSpesifikasiBarang == varian.idSpesifikasiBarang,
    );

    setState(() {
      _loadingUpdate = true;
      _showHasil = false;
      _searchCtrl.clear();
      _hasilCari = [];
    });

    try {
      if (idx >= 0) {
        // Sudah ada → tambah qty
        final newQty = _keranjang[idx].jumlah + 1;
        await _service.updateQuantityItem(
          idPesanan: widget.idPesanan,
          idSpesifikasiBarang: varian.idSpesifikasiBarang,
          jumlah: newQty,
        );
        setState(() => _keranjang[idx].jumlah = newQty);
      } else {
        // Baru → tambah dengan qty 1
        await _service.updateQuantityItem(
          idPesanan: widget.idPesanan,
          idSpesifikasiBarang: varian.idSpesifikasiBarang,
          jumlah: 1,
        );
        setState(() {
          _keranjang.add(ItemKeranjang(
            idPesanan: widget.idPesanan,
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

  // ── Update qty dari keranjang ────────────────────────────
  Future<void> _updateQty(int idx, int delta) async {
    final item = _keranjang[idx];
    final newQty = item.jumlah + delta;

    setState(() => _loadingUpdate = true);

    try {
      await _service.updateQuantityItem(
        idPesanan: widget.idPesanan,
        idSpesifikasiBarang: item.idSpesifikasiBarang,
        jumlah: newQty,
      );

      setState(() {
        if (newQty <= 0) {
          _keranjang.removeAt(idx);
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

  // ── Scanner ──────────────────────────────────────────────
  void _bukaScanner() {
    _scannerCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      // Landscape agar kamera memanjang ke bawah (portrait mode di UI)
      facing: CameraFacing.back,
    );
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

    final kode = barcode!.rawValue!;
    HapticFeedback.mediumImpact();
    _tutupScanner();
    _cari(kode);
  }

  // ── Helpers ──────────────────────────────────────────────
  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scannerCtrl?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Tampilan scanner fullscreen (portrait, kamera memanjang ke bawah)
    if (_scannerOpen) {
      return _buildScannerView();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: const Text(
          'Kasir POS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search Bar + Scan Button ───────────────────
          _buildSearchBar(),

          // ── Hasil Pencarian (dropdown style) ──────────
          if (_showHasil) _buildHasilCari(),

          // ── Keranjang / Empty State ────────────────────
          Expanded(
            child: _keranjang.isEmpty
                ? _buildEmptyState()
                : _buildKeranjang(),
          ),

          // ── Footer: Total + Tombol Bayar ──────────────
          if (_keranjang.isNotEmpty) _buildFooter(),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF8B4513),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: _cari,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari barang...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: _loadingCari
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _hasilCari = [];
                                  _showHasil = false;
                                });
                              },
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Tombol scan
          GestureDetector(
            onTap: _bukaScanner,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hasil Pencarian ───────────────────────────────────────
  Widget _buildHasilCari() {
    if (_loadingCari) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasilCari.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Produk tidak ditemukan',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.white,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _hasilCari.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final produk = _hasilCari[i];
          return _buildProdukTile(produk);
        },
      ),
    );
  }

  Widget _buildProdukTile(HasilCariProduk produk) {
    final punya1Varian = produk.varian.length == 1;

    return ExpansionTile(
      leading: produk.gambarBarang != null && produk.gambarBarang!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                produk.gambarBarang!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2),
              ),
            )
          : const Icon(Icons.inventory_2, color: Color(0xFF8B4513)),
      title: Text(
        produk.namaBarang,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: punya1Varian
          ? Text(_fmt.format(produk.varian.first.hargaDiskon > 0
              ? produk.varian.first.hargaDiskon
              : produk.varian.first.hargaBarang))
          : Text('${produk.varian.length} varian'),
      // Kalau hanya 1 varian, langsung tambah tanpa expand
      initiallyExpanded: punya1Varian,
      onExpansionChanged: punya1Varian
          ? (_) {
              _tambahItem(produk, produk.varian.first);
            }
          : null,
      children: produk.varian.map((v) {
        final harga = v.hargaDiskon > 0 ? v.hargaDiskon : v.hargaBarang;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text(v.label),
          subtitle: Text(
            _fmt.format(harga),
            style: const TextStyle(color: Color(0xFF8B4513)),
          ),
          trailing: Text(
            'Stok: ${v.stok}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          onTap: () => _tambahItem(produk, v),
        );
      }).toList(),
    );
  }

  // ── Empty State ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada barang',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cari barang atau scan barcode\nuntuk memulai transaksi',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Keranjang ─────────────────────────────────────────────
  Widget _buildKeranjang() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _keranjang.length,
      itemBuilder: (context, i) {
        final item = _keranjang[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaProduk,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (item.labelVarian.isNotEmpty)
                        Text(
                          item.labelVarian,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _fmt.format(item.subtotal),
                        style: const TextStyle(
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Qty control
                Row(
                  children: [
                    _qtyButton(
                      icon: Icons.remove,
                      onTap: _loadingUpdate ? null : () => _updateQty(i, -1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.jumlah}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _qtyButton(
                      icon: Icons.add,
                      onTap: _loadingUpdate ? null : () => _updateQty(i, 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade200
              : const Color(0xFF8B4513).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap == null ? Colors.grey.shade300 : const Color(0xFF8B4513),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey : const Color(0xFF8B4513),
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ringkasan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(color: Colors.grey.shade600)),
              Text(_fmt.format(_subtotal)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pajak (11%)', style: TextStyle(color: Colors.grey.shade600)),
              Text(_fmt.format(_pajak)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Akhir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                _fmt.format(_total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tombol Bayar
          ElevatedButton.icon(
            onPressed: _loadingUpdate ? null : _kePembayaran,
            icon: const Icon(Icons.payment),
            label: const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigator ke halaman pembayaran ──────────────────────
  void _kePembayaran() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MetodePembayaranScreen(
          idPesanan: widget.idPesanan,
          totalAkhir: _total,
          keranjang: _keranjang,
        ),
      ),
    );
  }

  // ── Scanner View (portrait, kamera penuh layar) ──────────
  Widget _buildScannerView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Kamera memanjang ke bawah penuh (portrait)
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerCtrl!,
              onDetect: _onBarcodeDetected,
              // fit: BoxFit.cover memastikan kamera memenuhi layar portrait
              fit: BoxFit.cover,
            ),
          ),

          // Overlay gelap di atas dan bawah, kotak scan di tengah
          Positioned.fill(
            child: CustomPaint(painter: _ScanOverlayPainter()),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _tutupScanner,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Scan Barcode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Tombol flash
                    IconButton(
                      onPressed: () => _scannerCtrl?.toggleTorch(),
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Label bawah
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arahkan kamera ke barcode produk',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay painter untuk kotak scan ─────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 250.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final boxRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: boxSize,
      height: boxSize,
    );

    final overlay = Paint()..color = Colors.black54;

    // Daerah gelap di luar kotak scan
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, boxRect.top), overlay);
    canvas.drawRect(Rect.fromLTRB(0, boxRect.top, boxRect.left, boxRect.bottom), overlay);
    canvas.drawRect(Rect.fromLTRB(boxRect.right, boxRect.top, size.width, boxRect.bottom), overlay);
    canvas.drawRect(Rect.fromLTRB(0, boxRect.bottom, size.width, size.height), overlay);

    // Border kotak scan
    final borderPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(12)),
      borderPaint,
    );

    // Corner highlights
    const cornerLen = 28.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(boxRect.left, boxRect.top + cornerLen), Offset(boxRect.left, boxRect.top), cornerPaint);
    canvas.drawLine(Offset(boxRect.left, boxRect.top), Offset(boxRect.left + cornerLen, boxRect.top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(boxRect.right - cornerLen, boxRect.top), Offset(boxRect.right, boxRect.top), cornerPaint);
    canvas.drawLine(Offset(boxRect.right, boxRect.top), Offset(boxRect.right, boxRect.top + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(boxRect.left, boxRect.bottom - cornerLen), Offset(boxRect.left, boxRect.bottom), cornerPaint);
    canvas.drawLine(Offset(boxRect.left, boxRect.bottom), Offset(boxRect.left + cornerLen, boxRect.bottom), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(boxRect.right, boxRect.bottom - cornerLen), Offset(boxRect.right, boxRect.bottom), cornerPaint);
    canvas.drawLine(Offset(boxRect.right, boxRect.bottom), Offset(boxRect.right - cornerLen, boxRect.bottom), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}