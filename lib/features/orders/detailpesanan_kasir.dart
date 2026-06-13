import 'package:flutter/material.dart';
import 'package:frontend/core/services/order_service.dart';

class DetailPesanan extends StatefulWidget {
  final String publicId;

  const DetailPesanan({super.key, required this.publicId});

  @override
  DetailPesananState createState() => DetailPesananState();
}

class DetailPesananState extends State<DetailPesanan> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic>? detailData;
  bool isLoading = true;

  // ── Palet warna ──────────────────────────────────────────
  static const Color _orange      = Color(0xFFAF510C);
  static const Color _orangeLight = Color(0xFFF5EDE7);
  static const Color _black       = Color(0xFF1A1A1A);
  static const Color _grey        = Color(0xFF566067);
  static const Color _greyLight   = Color(0xFFF4F4F4);
  static const Color _white       = Colors.white;
  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final data = await _orderService.getDetailPesanan(widget.publicId);
    if (mounted) {
      setState(() {
        detailData = data;
        isLoading = false;
      });
    }
  }

  String _formatRupiah(dynamic angka) {
    int val = int.tryParse(angka.toString()) ?? 0;
    return "Rp ${val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  // ── Status badge color ───────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFF2E7D32);
      case 'dibatalkan':
        return const Color(0xFFC62828);
      default:
        return _orange;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return const Color(0xFFE8F5E9);
      case 'dibatalkan':
        return const Color(0xFFFFEBEE);
      default:
        return _orangeLight;
    }
  }
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _greyLight,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: _orange),
        ),
      );
    }

    if (detailData == null) {
      return Scaffold(
        backgroundColor: _greyLight,
        appBar: _buildAppBar(),
        body: _buildEmptyState("Data tidak ditemukan"),
      );
    }

    // ── Logika asli (tidak diubah) ───────────────────────
    dynamic rawData = detailData;
    Map<String, dynamic>? data;

    List<dynamic> listPesanan = [];
    if (rawData is Map && rawData.containsKey('data')) {
      listPesanan = rawData['data'] as List<dynamic>;
    } else if (rawData is List) {
      listPesanan = rawData;
    }

    print("DEBUG: Mencari ID: ${widget.publicId}");
    for (var item in listPesanan) {
      print("DEBUG: Ada ID di server: ${item['id_pesanan']}");
    }
    String targetId =
        widget.publicId.replaceAll('#ORD-', '').toLowerCase();

    data = listPesanan.firstWhere(
      (item) =>
          item['id_pesanan'].toString().toLowerCase().startsWith(targetId),
      orElse: () => null,
    );
    // ─────────────────────────────────────────────────────

    if (data == null) {
      return Scaffold(
        backgroundColor: _greyLight,
        appBar: _buildAppBar(),
        body: _buildEmptyState("Pesanan tidak ditemukan"),
      );
    }

    final String idAsli = data['id_pesanan'] ?? widget.publicId;
    final String noPesananPendek = idAsli.length > 8
        ? "#ORD-" + idAsli.substring(0, 8).toUpperCase()
        : idAsli;

    final List items   = data['items'] ?? [];
    final String status     = data['status'] ?? 'Diproses';
    final String totalBayar = _formatRupiah(data['total_bayar'] ?? 0);
    const String metode     = "Tunai (Kasir)";

    return Scaffold(
      backgroundColor: _greyLight,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ─────────────────────────────
            _buildHeaderCard(noPesananPendek, status),

            const SizedBox(height: 16),

            // ── Section label ───────────────────────────
            _buildSectionLabel("ITEM PESANAN"),

            // ── Item list ───────────────────────────────
            ...items.asMap().entries.map((entry) {
              final int idx  = entry.key;
              final dynamic item = entry.value;
              return _buildItemCard(item, idx, items.length);
            }),

            const SizedBox(height: 16),

            // ── Section label ───────────────────────────
            _buildSectionLabel("RINGKASAN PEMBAYARAN"),

            // ── Payment summary card ─────────────────────
            _buildPaymentCard(metode, status, totalBayar),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        "Detail Pesanan",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      backgroundColor: _orange,
      foregroundColor: _white,
      elevation: 0,
      centerTitle: false,
    );
  }

  // ── Header card ──────────────────────────────────────────
  Widget _buildHeaderCard(String noPesanan, String status) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "No. Pesanan",
            style: TextStyle(
              color: Color(0xFFFFD5B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                noPesanan,
                style: const TextStyle(
                  color: _white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _buildStatusBadgeOnDark(status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadgeOnDark(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _white.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: _white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _grey,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Item card ────────────────────────────────────────────
  Widget _buildItemCard(dynamic item, int index, int total) {
    final int jumlah    = item['jumlah'] ?? 0;
    final dynamic harga = item['harga_saat_beli'] ?? 0;
    final String nama   = item['nama_barang'] ?? 'Produk';
    final subtotal      = jumlah * (int.tryParse(harga.toString()) ?? 0);

    // Rounded corners: top-only for first, bottom-only for last, square for middle
    final bool isFirst = index == 0;
    final bool isLast  = index == total - 1;
    final BorderRadius radius = BorderRadius.only(
      topLeft:     Radius.circular(isFirst ? 12 : 0),
      topRight:    Radius.circular(isFirst ? 12 : 0),
      bottomLeft:  Radius.circular(isLast  ? 12 : 0),
      bottomRight: Radius.circular(isLast  ? 12 : 0),
    );

    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        isFirst ? 0 : 0,
        16,
        isLast ? 0 : 1,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: radius,
        boxShadow: isFirst
            ? [
                const BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (!isFirst)
            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Item icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _orangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fastfood_rounded, color: _orange, size: 20),
                ),
                const SizedBox(width: 12),
                // Name + qty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          color: _black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$jumlah x ${_formatRupiah(harga)}",
                        style: const TextStyle(
                          color: _grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Subtotal
                Text(
                  _formatRupiah(subtotal),
                  style: const TextStyle(
                    color: _orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment summary card ─────────────────────────────────
  Widget _buildPaymentCard(String metode, String status, String total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPaymentRow(
            icon: Icons.payments_outlined,
            label: "Metode Pembayaran",
            value: metode,
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFEEEEEE)),
          _buildPaymentRow(
            icon: Icons.info_outline_rounded,
            label: "Status",
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBgColor(status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _statusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: _orangeLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: _orange, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Total Akhir",
                    style: TextStyle(
                      color: _orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  total,
                  style: const TextStyle(
                    color: _orange,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _grey, fontSize: 14),
            ),
          ),
          valueWidget ??
              Text(
                value ?? '',
                style: const TextStyle(
                  color: _black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _orangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, color: _orange, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: _grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Legacy helpers (tidak dipakai langsung di UI baru,
  //    tapi sengaja dibiarkan agar tidak break referensi lain) ──
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRowDetail(String label, String value,
      {bool isValueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _grey, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: _black,
            fontSize: 14,
            fontWeight: isValueBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}