import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/core/models/barang_model.dart';

class KategoriBarangPage extends StatefulWidget {
  // Tambahkan parameter initialCategory (opsional, default 'Semua')
  final String initialCategory;
  final List<dynamic> apiCategories;

  const KategoriBarangPage({
    Key? key,
    this.initialCategory = 'Semua',
    required this.apiCategories, // Wajib diisi saat pindah halaman
  }) : super(key: key);

  @override
  State<KategoriBarangPage> createState() => _KategoriBarangPageState();
}

class _KategoriBarangPageState extends State<KategoriBarangPage> {
  final ScrollController _scrollController = ScrollController();
  final KatalogService _katalogService = KatalogService();

  List<String> categories = [];
  late String selectedCategory;
  List<BarangModel> _produkList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    categories.add('Semua');
    for (var k in widget.apiCategories) {
      categories.add(k.namaKategori);
    }

    if (categories.contains(widget.initialCategory)) {
      selectedCategory = widget.initialCategory;
    } else {
      selectedCategory = 'Semua';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });

    _fetchProduk();
  }

  Future<void> _fetchProduk() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _katalogService.getDaftarBarang(limit: 50);
      if (mounted) {
        setState(() {
          _produkList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat produk';
          _isLoading = false;
        });
      }
    }
  }

  List<BarangModel> get _filteredProduk {
    if (selectedCategory == 'Semua') return _produkList;
    return _produkList.where((p) {
      final nama = p.namaBarang.toLowerCase();
      final kategori = selectedCategory.toLowerCase();
      return nama.contains(kategori);
    }).toList();
  }

  void _scrollToSelectedCategory() {
    int index = categories.indexOf(selectedCategory);

    // Jika index ditemukan dan bukan 'Semua' (index 0 tidak perlu digeser karena sudah di paling kiri)
    if (index > 0) {
      // 95.0 adalah estimasi lebar (lebar box + margin) tiap item kategori dalam pixel.
      // Kamu bisa menaikkan/menurunkan angka ini sedikit agar pas di tengah layar.
      double targetOffset = index * 95.0;

      // Cek apakah posisi scroll saat ini belum melampaui batas maksimum scroll ListView
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(
            milliseconds: 300,
          ), // Kecepatan geser (300 ms)
          curve: Curves.easeInOut, // Efek animasi halus
        );
      }
    }
  }

  // 4. Hapus controller dari memori saat halaman ditutup untuk mencegah memory leak
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filteredProduk;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      // Custom Header sesuai warna cokelat di gambar
      appBar: BaseHeaderWidget(
        title: 'Kategori Barang',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ==================== BOX KATEGORI HORIZONTAL ====================
          SizedBox(
            height: 40,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                bool isSelected = categories[index] == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = categories[index];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFAD510D)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFAD510D)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ==================== GRID BARANG / PRODUK ====================
          Expanded(
            child: _buildProdukGrid(filteredProducts, currencyFormat),
          ),
        ],
      ),
    );
  }

  Widget _buildProdukGrid(List<BarangModel> products, NumberFormat currencyFormat) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFAD510D)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchProduk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD510D),
                ),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
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
      itemCount: products.length,
      itemBuilder: (context, index) {
        final barang = products[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.blueGrey.shade100,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: barang.gambarBarang.isNotEmpty
                      ? Image.network(
                          barang.gambarBarang,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              color: Colors.grey,
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              barang.namaBarang,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              currencyFormat.format(barang.hargaTerendah),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }
}
