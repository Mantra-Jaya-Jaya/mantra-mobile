import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';

class KategoriBarangPage extends StatefulWidget {
  final String initialCategory;

  const KategoriBarangPage({Key? key, this.initialCategory = 'Semua'})
    : super(key: key);

  @override
  State<KategoriBarangPage> createState() => _KategoriBarangPageState();
}

class _KategoriBarangPageState extends State<KategoriBarangPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 2. Dummy Data Produk Sesuai Gambar
  final List<Map<String, dynamic>> products = [
    {
      'title': 'Totebag Wanita Kuliah',
      'price': 'Rp. 200.000',
      'image':
          'https://via.placeholder.com/150', // Ganti dengan asset/network image aslimu
      'category': 'Totebag',
    },
    {
      'title': 'Tas Punggung Laptop',
      'price': 'Rp. 400.000',
      'image': 'https://via.placeholder.com/150',
      'category': 'Laptop',
    },
    {
      'title': 'Tas Ransel Wanita',
      'price': 'Rp. 300.000',
      'image': 'https://via.placeholder.com/150',
      'category': 'Ransel',
    },
    {
      'title': 'Tas Selempang Wanita',
      'price': 'Rp. 200.000',
      'image': 'https://via.placeholder.com/150',
      'category': 'Selempang',
    },
    {
      'title': 'Tas Laptop Wanita',
      'price': 'Rp. 200.000',
      'image': 'https://via.placeholder.com/150',
      'category': 'Laptop',
    },
    {
      'title': 'Tas Bahu Pria',
      'price': 'Rp. 355.000',
      'image': 'https://via.placeholder.com/150',
      'category': 'Pria',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter produk berdasarkan kategori yang dipilih + search query
    List<Map<String, dynamic>> filteredProducts = products.where((p) {
      final matchCategory =
          widget.initialCategory == 'Semua' ||
          p['category'] == widget.initialCategory;
      final matchSearch =
          _searchQuery.isEmpty ||
          p['title']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: widget.initialCategory,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ==================== SEARCH BAR ====================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari Produk...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
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

          // ==================== GRID BARANG / PRODUK ====================
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('Tidak ada produk di kategori ini.'))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = filteredProducts[index];
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
                                child: Image.network(
                                  item['image']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['price']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
