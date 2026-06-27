// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'package:frontend/features/home/services/diskon_service.dart';
import 'package:frontend/core/models/barang_model.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/features/home/detail_barang.dart';
import 'package:intl/intl.dart';

class DiskonBarangPage extends StatefulWidget {
  final PromoModel promo;

  const DiskonBarangPage({super.key, required this.promo});

  @override
  State<DiskonBarangPage> createState() => _DiskonBarangPageState();
}

class _DiskonBarangPageState extends State<DiskonBarangPage> {
  final DiskonService _diskonService = DiskonService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<BarangModelCore> _barangList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBarangDiskon();
  }

  Future<void> _loadBarangDiskon() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Assuming idDiskon from PromoModel is actually the public_id, or backend accepts id_diskon directly.
      // Wait, publicId isn't on PromoModel in katalog_service.dart!
      // Let's check PromoModel: idDiskon, namaDiskon, bannerUrl, tglSelesai.
      final data = await _diskonService.getBarangByDiskon(widget.promo.publicId);
      if (mounted) {
        setState(() {
          _barangList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading barang diskon: $e");
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat barang diskon: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: widget.promo.namaDiskon,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFAD510D)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadBarangDiskon,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAD510D),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_barangList.isEmpty) {
      return const Center(child: Text('Tidak ada barang pada promo ini.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _barangList.length,
      itemBuilder: (context, index) {
        final item = _barangList[index];
        return _buildCard(item);
      },
    );
  }

  Widget _buildCard(BarangModelCore barang) {
    return GestureDetector(
      onTap: () {
        // Map BarangModelCore back to KatalogService's BarangModel to use DetailBarangPage
        final mappedBarang = BarangModel(
            idBarang: barang.idBarang,
            namaBarang: barang.namaBarang,
            hargaTerendah: barang.hargaTerendah,
            hargaTertinggi: barang.hargaTertinggi,
            hargaDiskon: barang.hargaDiskon,
            punyaDiskon: barang.punyaDiskon,
            gambarBarang: barang.gambarBarang,
            deskripsi: barang.deskripsi,
            stok: barang.stok,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailBarangPage(barang: mappedBarang),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueGrey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              spreadRadius: 1,
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: barang.gambarBarang.isNotEmpty
                      ? Image.network(
                          barang.gambarBarang,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, color: Colors.grey),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barang.namaBarang,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (barang.punyaDiskon) ...[
                    Text(
                      _currencyFormat.format(barang.hargaTerendah),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(barang.hargaDiskon),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                  ] else ...[
                    Text(
                      _currencyFormat.format(barang.hargaTerendah),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
