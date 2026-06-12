import 'package:flutter/material.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/features/home/kategori_barang_customer.dart';
import 'package:frontend/features/home/home_customer.dart'; // Import lokasi getIconFromString kamu

class AllKategoriPage extends StatefulWidget {
  final List<KategoriModel> initialCategories;

  const AllKategoriPage({super.key, required this.initialCategories});

  @override
  State<AllKategoriPage> createState() => _AllKategoriPageState();
}

class _AllKategoriPageState extends State<AllKategoriPage> {
  final KatalogService _katalogService = KatalogService();
  final TextEditingController _searchController = TextEditingController();

  List<KategoriModel> _allCategories = [];
  List<KategoriModel> _filteredCategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Gunakan data awal dari beranda terlebih dahulu agar instan
    _allCategories = widget.initialCategories;
    _filteredCategories = widget.initialCategories;

    // Tetap fetch ulang ke API tanpa limit untuk mengambil BENAR-BENAR SEMUA kategori di DB
    _fetchAllCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllCategories() async {
    // Jika data awal kosong, tampilkan loading. Jika tidak, fetch di background saja agar UX mulus
    if (_allCategories.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      // getKategori dipanggil tanpa limit agar keluar semua data di DB
      final data = await _katalogService.getKategori();
      if (mounted) {
        setState(() {
          _allCategories = data;
          // Jalankan filter ulang jika user keburu mengetik saat background loading selesai
          _filterCategories(_searchController.text);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _allCategories.isEmpty) {
        setState(() {
          _errorMessage = 'Gagal memuat semua kategori';
          _isLoading = false;
        });
      }
    }
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredCategories = _allCategories;
      } else {
        _filteredCategories = _allCategories
            .where(
              (kat) =>
                  kat.namaKategori.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 50, 20, 15),
          decoration: const BoxDecoration(color: Color(0xFFAD510D)),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCategories,
                  decoration: InputDecoration(
                    hintText: 'Cari Kategori...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _filterCategories('');
                            },
                          )
                        : null,
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

    if (_errorMessage != null && _allCategories.isEmpty) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
      );
    }

    if (_filteredCategories.isEmpty) {
      return const Center(
        child: Text(
          'Kategori tidak ditemukan.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(15),
      child: GridView.builder(
        itemCount: _filteredCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              3, // Diubah jadi 3 kolom agar ukuran card otomatis lebih besar
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.85, // Mempertahankan proporsi kotak ke bawah
        ),
        itemBuilder: (context, index) {
          final kat = _filteredCategories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KategoriBarangPage(
                    initialCategory: kat.namaKategori,
                    apiCategories:
                        _allCategories, // Mengirim full list kategori terupdate
                  ),
                ),
              );
            },
            child: _buildLargeCategoryItem(kat.namaKategori, kat.iconKategori),
          );
        },
      ),
    );
  }

  // Desain menyerupai komponen Beranda, namun dengan ukuran padding dan font yang dinaikkan
  Widget _buildLargeCategoryItem(String label, String? iconName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          // Menaikkan padding dari 10 ke 18 agar box lingkar luar terlihat lebih besar
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFAD510D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              15,
            ), // Border radius disesuaikan ukurannya
          ),
          // Ukuran icon dinaikkan dari 30 menjadi 36
          child: Icon(
            getIconFromString(iconName),
            color: const Color(0xFFAD510D),
            size: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13, // Ukuran teks dinaikkan dari 11 ke 13
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines:
              2, // Diubah ke 2 baris jika nama kategori panjang akibat card membesar
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
