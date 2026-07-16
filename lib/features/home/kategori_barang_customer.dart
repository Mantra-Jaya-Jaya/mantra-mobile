// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/features/home/detail_barang.dart';
import 'package:intl/intl.dart';

class KategoriBarangPage extends StatefulWidget {
  final KategoriModel category;

  const KategoriBarangPage({super.key, required this.category});

  @override
  State<KategoriBarangPage> createState() => _KategoriBarangPageState();
}

class _KategoriBarangPageState extends State<KategoriBarangPage> {
  final KatalogService _katalogService = KatalogService();
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<BarangModel> _allProducts = [];
  List<BarangModel> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _katalogService.getBarang(idKategori: widget.category.publicId);
      if (mounted) {
        setState(() {
          _allProducts = data;
          _filteredProducts = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat produk: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterProducts(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        return p.namaBarang.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: widget.category.namaKategori,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Cari Produk...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // GRID BARANG
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFAD510D)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAD510D),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return const Center(child: Text('Tidak ada produk di kategori ini.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final item = _filteredProducts[index];
        return _buildCard(item);
      },
    );
  }

  Widget _buildCard(BarangModel barang) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailBarangPage(barang: barang),
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
