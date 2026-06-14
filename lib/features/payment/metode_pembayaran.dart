import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/models/payment_model.dart';
import '../../core/services/payment_service.dart';
import 'bayarnontunai.dart';
import 'suksesbayar.dart';

// ── Design Tokens (sama dengan KasirPosScreen) ─────────────
class _K {
  static const orange = Color(0xFFAF510C);
  static const orangeLight = Color(0xFFFFE0CC);
  static const orangeDark = Color(0xFF8A3D06);
  static const black = Color(0xFF1A1A1A);
  static const grey900 = Color(0xFF2D2D2D);
  static const grey600 = Color(0xFF757575);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey100 = Color(0xFFF5F5F5);
  static const white = Color(0xFFFFFFFF);
}

class MetodePembayaranScreen extends StatefulWidget {
  final int idPesanan;
  final int totalAkhir;
  final List<ItemKeranjang> keranjang;

  const MetodePembayaranScreen({
    super.key,
    required this.idPesanan,
    required this.totalAkhir,
    required this.keranjang,
  });

  @override
  State<MetodePembayaranScreen> createState() => _MetodePembayaranScreenState();
}

class _MetodePembayaranScreenState extends State<MetodePembayaranScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _service = PaymentService();
  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _uangCtrl = TextEditingController();
  bool _loadingBayar = false;
  String _selectedMetode = 'qris';

  int? _backendTotal;
  String? _publicId;
  bool _syncing = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _syncData();
  }

  Future<void> _syncData() async {
    try {
      final ringkasan = await _service.getRingkasanCheckout(widget.idPesanan);
      if (mounted) {
        setState(() {
          _backendTotal = ringkasan.totalAkhir;
          _publicId = ringkasan.publicId;
          _syncing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _syncing = false);
      print("Gagal sinkron data checkout: $e");
    }
  }

  int get _subtotal => _backendTotal ?? widget.totalAkhir;
  int get _uangDiterima =>
      int.tryParse(_uangCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _kembalian =>
      (_uangDiterima - _subtotal) > 0 ? (_uangDiterima - _subtotal) : 0;
  bool get _isCukup => _uangDiterima >= _subtotal;

  Future<void> _konfirmasiBayarTunai() async {
    if (_syncing) return;
    print("ID Pesanan yang dikirim = ${widget.idPesanan}");
    setState(() => _loadingBayar = true);
    try {
      final hasil = await _service.bayarTunai(
          idPesanan: widget.idPesanan, uangDiterima: _uangDiterima);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => SuksesBayarScreen(
                  kembalian: hasil.kembalian,
                  nomorInvoice: hasil.nomorInvoice,
                  totalAkhir: _subtotal,
                  metodePembayaran: 'Tunai')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingBayar = false);
    }
  }

  Future<void> _prosesBayarNonTunai() async {
    if (_syncing) return;
    setState(() => _loadingBayar = true);
    try {
      // 🚀 1. Kirim parameter metode ke backend
      final hasil = await _service.bayarNonTunai(
        idPesanan: widget.idPesanan,
        metode: _selectedMetode,
      );

      if (!mounted) return;

      // 🚀 2. Lempar ke halaman QRIS/VA (yang nanti bakal kita benerin juga filenya)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BayarNonTunaiScreen(
            orderId: hasil.orderId,
            metode: hasil.metode,
            qrUrl: hasil.qrUrl,
            vaNumber: hasil.vaNumber,
            totalAkhir: _subtotal,
            publicId: _publicId ?? "",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: _K.orangeDark,
        ), // 🚀 Warnanya coklat gelap, bukan merah
      );
    } finally {
      if (mounted) setState(() => _loadingBayar = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _uangCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.grey100,
      appBar: _buildAppBar(),
      body: _syncing
          ? _buildLoading()
          : TabBarView(
              controller: _tabCtrl,
              children: [_buildTunaiTab(), _buildNonTunaiTab()],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _K.orange,
      foregroundColor: _K.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(left: 4, right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text('#${widget.idPesanan.toString().padLeft(5, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w400)),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: _K.orange,
            unselectedLabelColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            indicator: BoxDecoration(
              color: _K.white,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(3),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Tunai'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Non-Tunai'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _K.orange),
          const SizedBox(height: 16),
          Text('Memuat data pesanan…',
              style: TextStyle(color: _K.grey600, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Tunai Tab ──────────────────────────────────────────
  Widget _buildTunaiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Ringkasan Pesanan ──
          _buildRingkasanCard(),
          const SizedBox(height: 14),

          // ── Input uang ──
          Container(
            decoration: BoxDecoration(
              color: _K.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: _K.orangeLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.wallet_rounded, color: _K.orange, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Uang Diterima', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _K.black)),
                ]),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: _K.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _K.grey300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: _K.grey300,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                        ),
                        child: const Text('Rp', style: TextStyle(fontWeight: FontWeight.w700, color: _K.grey900, fontSize: 15)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _uangCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _K.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: _K.grey600),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol nominal cepat
                const SizedBox(height: 12),
                _buildNominalCepat(),

                // Status kembalian
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _uangDiterima == 0
                        ? _K.grey100
                        : _isCukup
                        ? _K.orangeLight
                        : _K.grey100, // 🚀 Ganti warna
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _uangDiterima == 0
                          ? _K.grey300
                          : _isCukup
                          ? _K.orange
                          : _K.grey600, // 🚀 Ganti warna
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _uangDiterima == 0
                            ? Icons.info_outline_rounded
                            : _isCukup
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: _uangDiterima == 0
                            ? _K.grey600
                            : _isCukup
                            ? _K.orange
                            : _K.grey600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      _uangDiterima == 0
                          ? const Text(
                              'Masukkan jumlah uang yang diterima',
                              style: TextStyle(fontSize: 13, color: _K.grey600),
                            )
                          : _isCukup
                          ? RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _K.orangeDark,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Kembalian: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _fmt.format(_kembalian),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _K.grey900,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Uang kurang: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _fmt.format(
                                      _subtotal - _uangDiterima,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildCTAButton(
            label: 'Konfirmasi Pembayaran',
            icon: Icons.check_circle_rounded,
            onPressed: (_loadingBayar || !_isCukup) ? null : _konfirmasiBayarTunai,
            loading: _loadingBayar,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Nominal cepat ──────────────────────────────────────
  Widget _buildNominalCepat() {
    final nominals = [
      _subtotal,
      _roundUp(_subtotal, 5000),
      _roundUp(_subtotal, 10000),
      _roundUp(_subtotal, 50000),
    ].toSet().toList()..sort();

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: nominals.take(4).map((n) {
        final isExact = n == _subtotal;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _uangCtrl.text = n.toString();
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isExact ? _K.orange : _K.orangeLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isExact ? _K.orange : _K.orange.withOpacity(0.3)),
            ),
            child: Text(
              isExact ? 'Pas ${_fmtShort(n)}' : _fmtShort(n),
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isExact ? _K.white : _K.orange,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  int _roundUp(int value, int to) {
    return ((value / to).ceil()) * to;
  }

  String _fmtShort(int v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}rb';
    return 'Rp $v';
  }

  // ── Non-Tunai Tab ──────────────────────────────────────
  Widget _buildNonTunaiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRingkasanCard(),
          const SizedBox(height: 24),

          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _K.black,
            ),
          ),
          const SizedBox(height: 12),

          // 🚀 List Pilihan Metode Pembayaran
          _buildPilihanMetode(
            value: 'qris',
            title: 'QRIS',
            subtitle: 'GoPay, OVO, DANA, ShopeePay',
            icon: Icons.qr_code_scanner_rounded,
          ),
          const SizedBox(height: 10),
          _buildPilihanMetode(
            value: 'bca',
            title: 'BCA Virtual Account',
            subtitle: 'Transfer via ATM / m-BCA',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 10),
          _buildPilihanMetode(
            value: 'bni',
            title: 'BNI Virtual Account',
            subtitle: 'Transfer via ATM / BNI Mobile',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 10),
          _buildPilihanMetode(
            value: 'bri',
            title: 'BRI Virtual Account',
            subtitle: 'Transfer via ATM / BRImo',
            icon: Icons.account_balance_rounded,
          ),

          const SizedBox(height: 24),
          _buildCTAButton(
            label: 'Konfirmasi Pembayaran',
            icon: Icons.check_circle_rounded,
            onPressed: _loadingBayar ? null : _prosesBayarNonTunai,
            loading: _loadingBayar,
          ),
        ],
      ),
    );
  }

  // 🚀 Widget kotak pilihan (Radio Button Custom)
  Widget _buildPilihanMetode({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMetode == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedMetode = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _K.orangeLight.withOpacity(0.3) : _K.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _K.orange : _K.grey300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _K.orange : _K.grey600, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? _K.orangeDark : _K.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: _K.grey600),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? _K.orange : _K.grey300,
            ),
          ],
        ),
      ),
    );
  }

  // ── Ringkasan Card ─────────────────────────────────────
  Widget _buildRingkasanCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_K.orange, _K.orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _K.orange.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('#${widget.idPesanan.toString().padLeft(5, '0')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${widget.keranjang.length} produk',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Total Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_fmt.format(_subtotal),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          // Item list ringkas
          ...widget.keranjang.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 5, height: 5,
                      margin: const EdgeInsets.only(right: 8, top: 1),
                      decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text('${item.namaProduk} (${item.jumlah}x)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text(_fmt.format(item.subtotal),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          if (widget.keranjang.length > 3)
            Text('+ ${widget.keranjang.length - 3} item lainnya…',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  // ── CTA Button ─────────────────────────────────────────
  Widget _buildCTAButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _K.orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _K.grey300,
          disabledForegroundColor: _K.grey600,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
      ),
    );
  }
}
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat formatter =
      NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue) {

    if (newValue.text.isEmpty) {
      return newValue;
    }

    String newText = newValue.text.replaceAll('.', '');

    int value = int.parse(newText);

    String formattedText = formatter.format(value);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: formattedText.length,
      ),
    );
  }
}