import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

// Model data untuk barang
class OrderItem {
  final String imageUrl;
  final String name;
  final String description;
  final int price;
  int quantity;

  OrderItem({
    required this.imageUrl,
    required this.name,
    required this.description,
    required this.price,
    this.quantity = 0,
  });
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Controller untuk mendeteksi ketikan di kolom pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // State untuk kamera inline
  CameraController? _cameraController;
  Future<void> _initializeControllerFuture = Future.value();
  bool _isCameraOpen = false;
  bool _isScanning = false;
  final BarcodeScanner _barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  // Master data daftar barang belanjaan di kasir
  List<OrderItem> items = [
    OrderItem(imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?q=80', name: 'Classic Burger', description: 'Fast Food', price: 45000, quantity: 2),
    OrderItem(imageUrl: 'https://images.unsplash.com/photo-1544787219-7f41bc75d78e?q=80', name: 'Iced Latte', description: 'Beverage', price: 28000, quantity: 1),
    OrderItem(imageUrl: 'https://images.unsplash.com/photo-1534111717085-f559f237f374?q=80', name: 'French Fries', description: 'Side Dish', price: 20000, quantity: 0),
  ];

  // LOGIKA PERHITUNGAN 1: Menghitung total item yang quantity-nya > 0 secara dinamis
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // LOGIKA PERHITUNGAN 2: Menghitung total belanjaan (harga * quantity) secara dinamis
  int get totalPrice => items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  // LOGIKA FILTER 3: Menyaring item berdasarkan apa yang diketik kasir di Search Bar
  List<OrderItem> get filteredItems {
    if (_searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  void initState() {
    super.initState();
    // Daftarkan listener agar setiap ada ketikan di search bar, UI langsung menyaring data
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  String formatRupiah(int number) {
    return 'Rp ' + number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // Fungsi Toggle pasang/lepas kamera inline
  void _toggleScanner() async {
    if (_isCameraOpen) {
      _closeCamera();
    } else {
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showSnackBar('Tidak ada hardware kamera terdeteksi');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      setState(() {
        _initializeControllerFuture = _cameraController!.initialize();
        _isCameraOpen = true;
      });
    } catch (e) {
      _showSnackBar('Gagal membuka kamera: $e');
    }
  }

  void _closeCamera() {
    _cameraController?.dispose();
    setState(() {
      _cameraController = null;
      _isCameraOpen = false;
    });
  }

  // Aksi scan manual via tombol di preview kamera inline
  Future<void> _scanCurrentFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) return;

    setState(() => _isScanning = true);

    try {
      final XFile image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final codeValue = barcodes.first.rawValue ?? '';
        _processScannedBarcode(codeValue);
      } else {
        _showSnackBar('Barcode tidak terdeteksi, posisikan ulang barang!');
      }
    } catch (e) {
      _showSnackBar('Error Scanner: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _processScannedBarcode(String code) {
    setState(() {
      // Dummy data simulasi deteksi barcode
      if (code == '8886001011123') {
        _addOrIncrementItem(OrderItem(
          imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80',
          name: 'Coca Cola Zero',
          description: 'Beverage',
          price: 12000,
          quantity: 1
        ));
      } else {
        _addOrIncrementItem(OrderItem(
          imageUrl: '', // Kosongkan agar memicu errorBuilder (kotak abu-abu)
          name: 'Scanned Food ($code)',
          description: 'Snack',
          price: 15000,
          quantity: 1
        ));
      }
    });
    _showSnackBar('Barang berhasil ditambahkan!');
  }

  void _addOrIncrementItem(OrderItem newItem) {
    int index = items.indexWhere((element) => element.name == newItem.name);
    if (index != -1) {
      items[index].quantity++;
    } else {
      items.add(newItem);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data hasil filter untuk di-render di ListView
    final displayItems = filteredItems;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFC1661A),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search & Scan Bar
          Container(
            color: const Color(0xFFC1661A),
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController, // Hubungkan controller ke TextField
                    decoration: InputDecoration(
                      hintText: 'Cari atau scan barang',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                GestureDetector(
                  onTap: _toggleScanner,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isCameraOpen ? Colors.white : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner, 
                      color: _isCameraOpen ? const Color(0xFFC1661A) : Colors.white, 
                      size: 26.0
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                // Tampilan Scanner Box Inline
                if (_isCameraOpen)
                  FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              color: Colors.black,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CameraPreview(_cameraController!),
                                Container(
                                  width: 220,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                if (_isScanning)
                                  const CircularProgressIndicator(color: Color(0xFFC1661A)),
                                Positioned(
                                  bottom: 10,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.flash_on, color: Colors.white),
                                        onPressed: () => _cameraController?.setFlashMode(FlashMode.torch),
                                      ),
                                      const SizedBox(width: 20),
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFC1661A),
                                        child: IconButton(
                                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                                          onPressed: _scanCurrentFrame,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      IconButton(
                                        icon: const Icon(Icons.flash_off, color: Colors.white),
                                        onPressed: () => _cameraController?.setFlashMode(FlashMode.off),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          height: 200,
                          margin: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFFC1661A))),
                        );
                      }
                    },
                  ),

                // List Items Kasir Belanjaan (Dinamis dari displayItems)
                displayItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Barang tidak ditemukan', style: TextStyle(color: Colors.grey))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Image.network(
                                      item.imageUrl,
                                      width: 65,
                                      height: 65,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 65,
                                          height: 65,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.fastfood, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(item.description, style: TextStyle(color: Colors.grey.shade500, fontSize: 13.0)),
                                        const SizedBox(height: 4.0),
                                        Text(formatRupiah(item.price), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC1661A))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  // Counter Tombol Tambah/Kurang
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6.0),
                                          icon: const Icon(Icons.remove, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              if (item.quantity > 0) item.quantity--;
                                            });
                                          },
                                        ),
                                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6.0),
                                          icon: const Icon(Icons.add, size: 18, color: Color(0xFFC1661A)),
                                          onPressed: () {
                                            setState(() {
                                              item.quantity++;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),

          // Bottom Summary (Perhitungan otomatis tercermin di sini)
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total ($totalItems Item)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14.0)),
                    Text(formatRupiah(totalPrice), style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (totalItems == 0) {
                      _showSnackBar('Keranjang belanja kosong!');
                    } else {
                      _showSnackBar('Melanjutkan ke pembayaran senilai ${formatRupiah(totalPrice)}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC1661A),
                    minimumSize: const Size(double.infinity, 52.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                    elevation: 0,
                  ),
                  child: const Text('Pilih Metode Pembayaran', style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}