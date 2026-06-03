import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/features/home/detail_barang.dart';

class SearchResultPage extends StatefulWidget {
  final String searchQuery;

  const SearchResultPage({super.key, required this.searchQuery});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final KatalogService _katalogService = KatalogService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late TextEditingController _headerSearchController;
  List<BarangModel> _searchResultList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan nilai kata kunci dari halaman sebelumnya
    _headerSearchController = TextEditingController(text: widget.searchQuery);
    _fetchSearchProducts(widget.searchQuery);
  }

  @override
  void dispose() {
    _headerSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSearchProducts(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mengambil data dari service katalog
      final data = await _katalogService.getDaftarBarang();

      // Filter data berdasarkan namaBarang secara lokal
      final filteredData = data
          .where(
            (barang) =>
                barang.namaBarang.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      if (mounted) {
        setState(() {
          _searchResultList = filteredData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat hasil pencarian';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Custom Header berbentuk melengkung dengan tombol kembali & kolom search bawaan keyword
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 50, 20, 20),
          decoration: const BoxDecoration(color: Color(0xFFAD510D)),
          child: Row(
            children: [
              // Tombol panah kembali ke halaman search_page
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 5),
              // Kolom Search yang menampilkan keyword aktif
              Expanded(
                child: TextField(
                  controller: _headerSearchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    _fetchSearchProducts(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari Barang',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _headerSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              _headerSearchController.clear();
                              setState(() {});
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
                  onChanged: (value) => setState(() {}),
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

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_searchResultList.isEmpty) {
      return const Center(
        child: Text(
          'Barang yang Anda cari tidak ditemukan.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: GridView.builder(
        itemCount: _searchResultList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          return _buildProductCard(_searchResultList[index]);
        },
      ),
    );
  }

  // Card UI yang disesuaikan penuh dengan logika kartu produk halaman beranda Anda
  // Card UI yang disesuaikan penuh dengan logika kartu produk halaman beranda Anda
  Widget _buildProductCard(BarangModel barang) {
    return GestureDetector(
      onTap: () {
        // 👈 Fungsi navigasi untuk berpindah ke halaman detail sambil membawa data objek barang
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailBarangPage(barang: barang),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: barang.gambarBarang.isNotEmpty
                    ? Image.network(
                        barang.gambarBarang,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barang.namaBarang,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  if (barang.punyaDiskon) ...[
                    Text(
                      _currencyFormat.format(barang.hargaTerendah),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(barang.hargaDiskon),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    Text(
                      _currencyFormat.format(barang.hargaTerendah),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
