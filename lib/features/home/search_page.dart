import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_result_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  // Mengambil data riwayat dari penyimpanan lokal perangkat
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  // Menyimpan kata kunci pencarian baru ke lokal
  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Hapus jika query sudah ada sebelumnya agar tidak duplikat, lalu taruh di urutan paling depan
      _searchHistory.remove(query.trim());
      _searchHistory.insert(0, query.trim());

      // Batasi maksimal 10 riwayat pencarian saja
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
    await prefs.setStringList('search_history', _searchHistory);
  }

  // Menghapus seluruh riwayat pencarian
  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory.clear();
    });
    await prefs.remove('search_history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. Menggunakan Custom Header/AppBar yang menampung kolom search & tombol Batal secara horizontal
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
          110,
        ), // Menyesuaikan tinggi header area kontainer
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          decoration: const BoxDecoration(
            color: Color(
              0xFFAD510D,
            ), // Menggunakan warna tema utama MANTRA Anda (Cokelat Oranye)
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus:
                      true, // Otomatis memunculkan keyboard saat masuk halaman ini
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _saveSearch(value); // Tetap simpan ke riwayat lokal

                      // Pindah ke halaman hasil pencarian sambil membawa kata kunci
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SearchResultPage(searchQuery: value.trim()),
                        ),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari Barang',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
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
              const SizedBox(width: 15),
              // Tombol Batal diposisikan sejajar horizontal di ujung kanan header
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. Baris Judul Sub-Section "Riwayat Pencarian" dan Tombol "Hapus Semua" secara horizontal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Pencarian',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // Tombol Hapus Semua hanya aktif/terlihat penuh jika history tidak kosong
                  if (_searchHistory.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAllHistory,
                      child: const Text(
                        'Hapus Semua',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(
                            0xFFAD510D,
                          ), // Seragam menggunakan warna aksen aplikasi
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),

              // 3. Kondisi Penanganan Render List History atau Fallback Teks Kosong
              if (_searchHistory.isEmpty)
                // Ditampilkan di tengah layar bagian bawah jika riwayat masih kosong
                const Expanded(
                  child: Center(
                    child: Text(
                      'Belum ada riwayat pencarian',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                // Menampilkan tumpukan kotak Chips kata kunci pencarian
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _searchHistory.map((keyword) {
                    return GestureDetector(
                      onTap: () {
                        _searchController.text = keyword;
                        _saveSearch(keyword);
                        // TODO: Jalankan reload data API berdasarkan kata kunci dari chips di sini
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE9EEF4,
                          ), // Warna background abu-biru muda soft
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          keyword,
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
