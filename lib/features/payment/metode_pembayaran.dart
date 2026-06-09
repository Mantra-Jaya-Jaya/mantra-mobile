import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/models/payment_model.dart';
import '../../core/services/payment_service.dart';
import 'bayarnontunai.dart';
import 'suksesbayar.dart';

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

  // Tunai
  final _uangCtrl = TextEditingController();
  bool _loadingBayar = false;

  int get _uangDiterima {
    final raw = _uangCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(raw) ?? 0;
  }

  int get _kembalian {
    final k = _uangDiterima - widget.totalAkhir;
    return k > 0 ? k : 0;
  }

  bool get _uangCukup => _uangDiterima >= widget.totalAkhir;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _uangCtrl.dispose();
    super.dispose();
  }

  // ── Bayar Tunai ───────────────────────────────────────────
  Future<void> _konfirmasiBayarTunai() async {
    if (!_uangCukup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Uang yang diterima kurang'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loadingBayar = true);

    try {
      final hasil = await _service.bayarTunai(
        idPesanan: widget.idPesanan,
        uangDiterima: _uangDiterima,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SuksesBayarScreen(
            kembalian: hasil.kembalian,
            nomorInvoice: hasil.nomorInvoice,
            totalAkhir: widget.totalAkhir,
            metodePembayaran: 'Tunai',
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingBayar = false);
    }
  }

  // ── Ke halaman Non-Tunai (Midtrans) ──────────────────────
  Future<void> _prosesBayarNonTunai() async {
    setState(() => _loadingBayar = true);

    try {
      final hasil = await _service.bayarNonTunai(widget.idPesanan);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BayarNonTunaiScreen(
            snapToken: hasil.snapToken,
            idPesanan: widget.idPesanan,
            totalAkhir: widget.totalAkhir,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingBayar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.payments_outlined),
                  SizedBox(width: 6),
                  Text('Tunai', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.credit_card_outlined),
                  SizedBox(width: 6),
                  Text('Non-tunai', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTunaiTab(),
          _buildNonTunaiTab(),
        ],
      ),
    );
  }

  // ── Tab Tunai ─────────────────────────────────────────────
  Widget _buildTunaiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input uang diterima
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uang Diterima',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Rp',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _uangCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.black26),
                          ),
                        ),
                      ),
                      // Tombol "Pas"
                      GestureDetector(
                        onTap: () {
                          _uangCtrl.text = widget.totalAkhir.toString();
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF8B4513).withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Pas',
                            style: TextStyle(
                              color: Color(0xFF8B4513),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_uangCtrl.text.isNotEmpty) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian'),
                        Text(
                          _fmt.format(_kembalian),
                          style: TextStyle(
                            color: _uangCukup
                                ? const Color(0xFF8B4513)
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Daftar item
          _buildDaftarItem(),

          const SizedBox(height: 16),

          // Ringkasan biaya
          _buildRingkasanBiaya(),

          const SizedBox(height: 20),

          // Tombol konfirmasi
          ElevatedButton.icon(
            onPressed: _loadingBayar ? null : _konfirmasiBayarTunai,
            icon: _loadingBayar
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _loadingBayar ? 'Memproses...' : 'Konfirmasi Pembayaran',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Non-Tunai ─────────────────────────────────────────
  Widget _buildNonTunaiTab() {
    // Daftar metode Midtrans (sesuai gambar 2)
    final metodeList = [
      _MetodeMidtrans(
        icon: Icons.credit_card,
        label: 'Cards',
        subtitle: 'Visa, Mastercard, JCB, Amex',
      ),
      _MetodeMidtrans(
        icon: Icons.account_balance,
        label: 'Virtual Accounts',
        subtitle: 'BCA, BNI, BRI, Mandiri, Permata',
      ),
      _MetodeMidtrans(
        icon: Icons.qr_code,
        label: 'QRIS',
        subtitle: 'GoPay, OVO, Dana, ShopeePay, LinkAja',
      ),
      _MetodeMidtrans(
        icon: Icons.account_balance_wallet,
        label: 'E-Wallets',
        subtitle: 'GoPay, t-cash, Mandiri e-cash',
      ),
      _MetodeMidtrans(
        icon: Icons.store,
        label: 'Retail Outlets',
        subtitle: 'Alfamart, Indomaret, dll.',
      ),
      _MetodeMidtrans(
        icon: Icons.swap_horiz,
        label: 'Direct Debit',
        subtitle: 'e-Pay BRI, Clickpay, BCAKlikPay',
      ),
      _MetodeMidtrans(
        icon: Icons.wallet,
        label: 'Cardless Credit',
        subtitle: 'Akulaku PayLater',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'METODE PEMBAYARAN MIDTRANS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: metodeList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = metodeList[i];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(m.icon, color: const Color(0xFF8B4513)),
                  ),
                  title: Text(m.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(m.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  trailing: const Icon(Icons.expand_more, color: Colors.grey),
                  onTap: _loadingBayar ? null : _prosesBayarNonTunai,
                ),
              );
            },
          ),
        ),
        // Footer total
        Container(
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
            children: [
              _buildRingkasanBiaya(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadingBayar ? null : _prosesBayarNonTunai,
                  icon: _loadingBayar
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _loadingBayar ? 'Menghubungkan ke Midtrans...' : 'Lanjut ke Pembayaran',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────
  Widget _buildDaftarItem() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: widget.keranjang.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.namaProduk,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (item.labelVarian.isNotEmpty)
                          Text(
                            '${item.jumlah}x ${item.labelVarian}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          )
                        else
                          Text(
                            '${item.jumlah}x ${_fmt.format(item.hargaSatuan)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  Text(_fmt.format(item.subtotal)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRingkasanBiaya() {
    final subtotal = widget.keranjang.fold(0, (s, i) => s + i.subtotal);
    final pajak = (subtotal * 0.11).round();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: TextStyle(color: Colors.grey.shade600)),
            Text(_fmt.format(subtotal)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pajak (11%)', style: TextStyle(color: Colors.grey.shade600)),
            Text(_fmt.format(pajak)),
          ],
        ),
        const Divider(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Akhir',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _fmt.format(widget.totalAkhir),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF8B4513),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetodeMidtrans {
  final IconData icon;
  final String label;
  final String subtitle;
  _MetodeMidtrans({required this.icon, required this.label, required this.subtitle});
}