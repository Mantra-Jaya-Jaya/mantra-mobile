import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import 'package:frontend/core/models/alamat_model.dart';
import '../../core/widgets/base_header_widget.dart';

class OrderDetailPage extends StatefulWidget {
  final String noPesanan;
  final String namaProduk;
  final String statusLabel;
  final Color warnaStatus;
  final String tanggalPesanan;

  const OrderDetailPage({
    super.key,
    required this.noPesanan,
    required this.namaProduk,
    required this.statusLabel,
    required this.warnaStatus,
    required this.tanggalPesanan,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ProfileService _profileService = ProfileService();
  bool _isLoadingAlamat = true;
  AlamatModel? _alamatUtama;
  String? _alamatErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAlamatCustomer();
  }

  // Mengambil data alamat dari API profile_service dan menyaring alamat utama (isUtama)
  Future<void> _fetchAlamatCustomer() async {
    try {
      final List<dynamic> alamatRawData = await _profileService.getAlamat();
      final List<AlamatModel> daftarAlamat = alamatRawData
          .map((json) => AlamatModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cari alamat yang di-set sebagai alamat utama (isUtama == true atau 1)
      final utama = daftarAlamat.firstWhere(
        (alamat) => alamat.isUtama == true,
        orElse: () => daftarAlamat.isNotEmpty
            ? daftarAlamat.first
            : AlamatModel(
                idAlamat: '',
                labelAlamat: 'Rumah',
                namaPenerima: '-',
                noTelpPenerima: '-',
                alamatLengkap: 'Belum ada alamat utama yang diatur.',
                isUtama: false,
                // Tambahkan parameter wajib yang kurang di bawah ini:
                publicId: '',
                idCustomer: '',
                latitude:
                    0.0, // sesuaikan tipe datanya, jika double ganti jadi 0.0
                longitude:
                    0.0, // sesuaikan tipe datanya, jika double ganti jadi 0.0
                catatanLokasi: '',
              ),
      );

      if (mounted) {
        setState(() {
          _alamatUtama = utama;
          _isLoadingAlamat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAlamat = false;
          _alamatErrorMessage = "Gagal memuat alamat pengantaran";
        });
      }
    }
  }

  String _formatRupiah(int number) {
    return 'Rp. ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}, 00';
  }

  @override
  Widget build(BuildContext context) {
    // Penyesuaian list item mockup: jika halaman sebelumnya melempar item,
    // di sini kita simulasikan daftar barang (menyesuaikan gambar mockup yang berisi 3 item)
    List<Map<String, dynamic>> itemsDetail = [
      {
        'title':
            widget.namaProduk, // Menyesuaikan dinamis dari card yang diklik
        'qty': 1,
        'price': 50000,
        'icon': Icons.book_outlined,
      },
    ];

    int deliveryFee = 20000;
    int protectionFee =
        20000; // Sesuai total visual Rp 172.000 jika subtotal item Rp 150.000 (dikurang delivery fee)
    int totalItemsPrice = itemsDetail.fold(
      0,
      (sum, item) => sum + (item['price'] as int),
    );
    int subtotalAkhir =
        totalItemsPrice +
        deliveryFee +
        2000; // Protection fee di gambar tertulis 2.000,00 namun kalkulasi total 172.000 (2.000 + 20.000 + 150.000)

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: 'Detail Pesanan',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NOMOR PESANAN & STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "No. Pesanan",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.noPesanan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.warnaStatus.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.statusLabel,
                    style: TextStyle(
                      color: widget.warnaStatus,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1),

            // --- DAFTAR BARANG ---
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsDetail.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                var item = itemsDetail[index];
                return Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'], color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${item['qty']} item",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Rp. 50.000",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 35, thickness: 1),

            // --- TUJUAN PENGANTARAN (PANGGIL API ALAMAT) ---
            const Text(
              "Tujuan Pengantaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _isLoadingAlamat
                ? const LinearProgressIndicator(color: Color(0xFFAD510D))
                : _alamatErrorMessage != null
                ? Text(
                    _alamatErrorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _alamatUtama?.namaPenerima ?? "-",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _alamatUtama?.alamatLengkap ?? "-",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
            const Divider(height: 35, thickness: 1),

            // --- KURIR ---
            const Text(
              "Kurir",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ricardo Holahilo",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "H 6582 TH",
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "SPEX Express",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 35, thickness: 1),

            // --- TOTAL RINCIAN ---
            const Text(
              "Total",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildRowTotal("Item 1", "x1", "Rp. 50.000, 00"),
            _buildRowTotal("Item 2", "x1", "Rp. 50.000, 00"),
            _buildRowTotal("Item 3", "x1", "Rp. 50.000, 00"),
            _buildRowTotal("Delivery fee", "", "Rp. 20.000, 00"),
            _buildRowTotal("Protection fee", "", "Rp. 2.000, 00"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subtotal",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _formatRupiah(subtotalAkhir),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- TOMBOL LACAK PESANAN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Tambahkan fungsionalitas pelacakan kurir/pesanan di sini
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD510D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Lacak Pesanan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowTotal(String label, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              qty,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Text(price, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }
}
