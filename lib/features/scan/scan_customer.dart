// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../main.dart'
    as app;
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/features/home/detail_barang.dart';
import 'package:intl/intl.dart';

class ScanPage extends StatefulWidget {
  final bool isActive;
  const ScanPage({super.key, this.isActive = true});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with WidgetsBindingObserver, RouteAware {
  final MobileScannerController scannerController = MobileScannerController();
  final ApiClient _client = ApiClient();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? barcodeTerdeteksi;
  String namaBarang = "Menunggu Scan...";
  String hargaBarang = "-";
  String gambarBarang = "";
  String? scanPublicId;
  bool isFound = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  void cekBarcode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final response = await _client.dio.get('/scan/$code');
      final data = response.data['data'];

      final varians = data['varian'] as List? ?? [];
      int harga = 0;
      if (varians.isNotEmpty) {
        harga = (varians.first['harga_barang'] ?? 0).toInt();
      }

      final rawPublicId = data['public_id'];
      final publicIdStr = rawPublicId?.toString();

      setState(() {
        barcodeTerdeteksi = code;
        scanPublicId = publicIdStr;
        namaBarang = data['nama_barang'] ?? 'Barang Tidak Diketahui';
        hargaBarang = _currencyFormat.format(harga);
        gambarBarang = data['gambar_barang'] ?? '';
        isFound = true;
      });
    } catch (e) {
      setState(() {
        namaBarang = "Barang Tidak Terdaftar";
        hargaBarang = "-";
        gambarBarang = "";
        isFound = false;
      });
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Daftarkan observer untuk mendeteksi perubahan lifecycle aplikasi
    WidgetsBinding.instance.addObserver(this);

    // Daftarkan ke RouteObserver global dari main.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Route<dynamic>? route = ModalRoute.of(context);
      if (route is PageRoute) {
        app.routeObserver.subscribe(this, route);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        scannerController.start();
      } else {
        scannerController.stop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Pause camera ketika aplikasi di background
        scannerController.stop();
        break;
      case AppLifecycleState.resumed:
        // Resume camera ketika aplikasi kembali ke foreground
        // Tapi hanya jika halaman ini sedang aktif
        if (mounted) {
          scannerController.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle state lainnya jika diperlukan
        break;
    }
  }

  // RouteAware method - dipanggil ketika route ini di-push ke navigation stack
  @override
  void didPush() {
    // Izin kamera diminta hanya ketika halaman ini benar-benar ditampilkan
    if (mounted) {
      scannerController.start();
    }
  }

  // RouteAware method - dipanggil ketika route lain di-pop, menampilkan route ini kembali
  @override
  void didPopNext() {
    if (mounted) {
      scannerController.start();
    }
  }

  // RouteAware method - dipanggil ketika route lain di-push, menyembunyikan route ini
  @override
  void didPushNext() {
    if (mounted) {
      scannerController.stop();
    }
  }

  // RouteAware method - dipanggil ketika route ini di-pop dari navigation stack
  @override
  void didPop() {
    if (mounted) {
      scannerController.stop();
    }
  }

  @override
  void deactivate() {
    // Hentikan scanner ketika halaman ini tidak lagi aktif
    if (mounted) {
      scannerController.stop();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    // Hapus observer sebelum dispose
    WidgetsBinding.instance.removeObserver(this);
    // Unsubscribe dari RouteObserver global
    app.routeObserver.unsubscribe(this);
    // Matikan kamera sebelum halaman benar-benar hancur
    scannerController.dispose();
    super.dispose();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(Icons.info_outline, size: 48, color: Color(0xFFAF510C)),
              SizedBox(height: 16),
              Text(
                'Arahkan kamera ke barcode barang untuk melihat informasi barang',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', textAlign: TextAlign.center),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BaseHeaderWidget(
        title: "Cek Harga",

        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () async {
              await scannerController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // ================= AREA KAMERA =================
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.black,
            ),
            clipBehavior: Clip.antiAlias, // Agar kamera ikut melengkung
            child: MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                if (_isProcessing) return;

                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    cekBarcode(barcode.rawValue!);
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          if (isFound && scanPublicId != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailBarangPage(
                      barang: BarangModel(
                        idBarang: scanPublicId!,
                        namaBarang: namaBarang,
                        gambarBarang: gambarBarang,
                        deskripsi: "",
                        hargaTerendah: 0,
                        hargaTertinggi: 0,
                        hargaDiskon: 0,
                        punyaDiskon: false,
                        stok: "",
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.search, size: 18),
              label: const Text("Lihat Detail"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAF510C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ================= CARD HASIL SCAN =================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFEF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Gambar Barang
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isFound && gambarBarang.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            gambarBarang,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, color: Colors.grey);
                            },
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Info Barang
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaBarang,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hargaBarang,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
