import 'package:flutter/material.dart';
import 'checkout.dart'; // Pastikan import halaman checkout
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'package:frontend/features/home/services/cart_service.dart'; // Import CartService untuk komunikasi dengan backend

class CartCustomerPage extends StatefulWidget {
  const CartCustomerPage({super.key});

  @override
  State<CartCustomerPage> createState() => _CartCustomerPageState();
}

class _CartCustomerPageState extends State<CartCustomerPage> {
  final CartService _cartService = CartService();
  List<Map<String, dynamic>> cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  // Fungsi mengambil data dari server Golang
  Future<void> _loadCartData() async {
    try {
      final data = await _cartService.getCartItems();
      setState(() {
        // Pastikan setiap item memiliki field 'isSelected' secara lokal untuk melacak centang UI
        cartItems = data.map((item) {
          item['isSelected'] = item['isSelected'] ?? false;
          // 🔥 Mapping field backend Golang ke field UI Flutter
          item['id'] = item['id_spesifikasi_barang']; // ID varian unik
          item['title'] = item['nama_barang'] ?? 'Nama Produk';
          item['subtitle'] = item['varian'] ?? 'Detail Pemesanan';
          item['price'] = item['harga_diskon'] ?? item['harga_barang'] ?? 0;
          item['image'] =
              item['gambar_barang'] ??
              'assets/images/produk.png'; // Menggunakan key 'image'
          return item;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data keranjang')),
        );
      }
    }
  }

  // Fungsi memperbarui kuantitas ke database (PATCH)
  Future<void> _changeQuantity(int index, int newQuantity) async {
    final item = cartItems[index];
    final idKeranjang = item['id_keranjang'].toString();

    try {
      await _cartService.updateCartQuantity(
        idKeranjang: idKeranjang,
        newQuantity: newQuantity,
      );
      setState(() {
        item['quantity'] = newQuantity;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui jumlah barang')),
        );
      }
    }
  }

  // Fungsi menghapus barang dari database (DELETE)
  Future<void> _deleteItem(int index) async {
    final idKeranjang = cartItems[index]['id_keranjang'].toString();
    try {
      await _cartService.deleteCartItem(idKeranjang);
      setState(() {
        cartItems.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang berhasil dihapus dari keranjang'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus barang')));
      }
    }
  }

  // Menghitung total harga dari item yang dicentang saja
  int get totalHargaCentang {
    int total = 0;
    for (var item in cartItems) {
      if (item['isSelected'] == true) {
        final price = item['price'] ?? 0;
        final qty = item['quantity'] ?? 0;
        total += (price as int) * (qty as int);
      }
    }
    return total;
  }

  String _formatRupiah(int number) {
    return 'Rp. ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    bool isAnyItemSelected = cartItems.any(
      (item) => item['isSelected'] == true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: BaseHeaderWidget(
        title: 'Keranjang Saya',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),

      // FIX 1: Body sekarang fokus hanya menampilkan state Loading, Kosong, atau List Data.
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFAD510D)),
            )
          : cartItems.isEmpty
          ? const Center(
              child: Text(
                'Keranjang belanjaanmu masih kosong',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(index);
              },
            ),

      // FIX 2: bottomNavigationBar diletakkan sejajar dengan body (di bawah naungan langsung Scaffold)
      bottomNavigationBar: cartItems.isEmpty || _isLoading
          ? null // Sembunyikan total pesanan jika data kosong/loading
          : Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 24, // Aman untuk HP ber-notch bawah
                top: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Sesuai tinggi konten
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pesanan',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(totalHargaCentang),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isAnyItemSelected
                          ? () {
                              List<Map<String, dynamic>> selectedItems =
                                  cartItems
                                      .where(
                                        (item) => item['isSelected'] == true,
                                      )
                                      .toList();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Checkout(selectedProducts: selectedItems),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD510D),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Lanjut ke Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCartItem(int index) {
    var item = cartItems[index];
    // FIX 3: Ambil value gambar dari key 'image' yang sudah di-mapping di atas (bukan imagePath)
    String imagePath = item['image'] ?? 'assets/images/produk.png';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox Custom
              GestureDetector(
                onTap: () {
                  setState(() {
                    item['isSelected'] = !item['isSelected'];
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: item['isSelected'] == true
                        ? const Color(0xFFAD510D)
                        : Colors.white,
                    border: Border.all(
                      color: item['isSelected'] == true
                          ? const Color(0xFFAD510D)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: item['isSelected'] == true
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Render Gambar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imagePath.startsWith('http')
                      ? Image.network(imagePath, fit: BoxFit.cover)
                      : Image.asset(imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Nama Produk',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] ?? 'Detail Pemesanan',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(item['price'] ?? 0),
                      style: const TextStyle(
                        color: Color(0xFFAD510D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Tombol Kurangi Kuantitas (PATCH)
                  GestureDetector(
                    onTap: () {
                      if (item['quantity'] > 1) {
                        _changeQuantity(index, item['quantity'] - 1);
                      }
                    },
                    child: _quantityButton(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item['quantity'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Tombol Tambah Kuantitas (PATCH)
                  GestureDetector(
                    onTap: () {
                      _changeQuantity(index, item['quantity'] + 1);
                    },
                    child: _quantityButton(Icons.add),
                  ),
                ],
              ),
              // Tombol Hapus Item (DELETE)
              GestureDetector(
                onTap: () => _deleteItem(index),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: Colors.black54),
    );
  }
}
