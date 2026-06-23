import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/pengantaran_service.dart';
import '../../core/widgets/global_appbar_kurir.dart';

class AmbilBuktiPage extends StatefulWidget {
  final String publicId;

  const AmbilBuktiPage({super.key, required this.publicId});

  @override
  State<AmbilBuktiPage> createState() => _AmbilBuktiPageState();
}

class _AmbilBuktiPageState extends State<AmbilBuktiPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _imageFile;
  bool _isUploading = false;
  bool _cameraError = false;
  String _cameraErrorMessage = '';

  final DetailPengantaranService _service = DetailPengantaranService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // Jika controller belum ada atau belum inisialisasi, skip saja
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free up camera resources ketika app minimize / background
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize kamera ketika app dibuka kembali
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _cameraErrorMessage = 'Izin kamera tidak diberikan.';
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _cameraErrorMessage = 'Tidak ada kamera tersedia.';
          });
        }
        return;
      }

      final newController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await newController.initialize();

      // Mencegah memory leak & black screen:
      // Jika user keburu pencet "Back" sebelum kamera selesai loading,
      // kita harus segera dispose controller yang baru terbuat ini.
      if (!mounted) {
        newController.dispose();
        return;
      }

      _cameraController = newController;
      setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraError = true;
          _cameraErrorMessage = 'Gagal mengakses kamera: ${e.toString()}';
        });
      }
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    // Cari kamera depan/belakang berdasarkan yang lagi aktif
    final lensDirection = _cameraController!.description.lensDirection;
    CameraDescription newCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection != lensDirection,
      orElse: () => _cameras![0],
    );

    await _cameraController!.dispose();
    
    final newController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    try {
      await newController.initialize();
      if (!mounted) {
        newController.dispose();
        return;
      }
      _cameraController = newController;
      setState(() {});
    } catch (e) {
      debugPrint('Switch camera error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      // 🚀 EFEK KAMERA: Bunyi "Cekring" (Suara Sistem) + Getar (Haptic)
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();

      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  Future<void> _uploadGambar() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    // 🚀 TEMBAK API KE BACKEND GOLANG LU
    final result = await _service.uploadBuktiSelesai(
      widget.publicId,
      File(_imageFile!.path),
    );

    setState(() => _isUploading = false);

    if (result != null) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal upload bukti! Coba lagi ya.')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Berhasil Menyimpan\nBukti Pengantaran!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAD510D), // Coklat
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup Dialog
                      Navigator.of(context).pop(true); // Tutup Kamera + kirim hasil sukses ke Detail
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAD510D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Kembali',
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
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🚀 Background utama warna coklat khas aplikasi lu
      backgroundColor: const Color(0xFFAD510D),
      appBar: GlobalAppBarKurir(
        title: 'Bukti Pengantaran',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16), // Jarak dari Appbar biar manis
            // ==========================================
            // 🚀 AREA KAMERA DENGAN FRAME MELENGKUNG
            // ==========================================
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black, // Warna dasar frame
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30), // Lengkungan atas
                    bottom: Radius.circular(
                      30,
                    ), // 🚀 Lengkungan bawah sesuai request!
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  // 🚀 Potong isi kamera ngikutin lengkungan wadahnya
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                    bottom: Radius.circular(30),
                  ),
                  child: _imageFile != null
                      ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                      : _cameraError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _cameraErrorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _cameraError = false;
                                      _cameraErrorMessage = '';
                                    });
                                    _initCamera();
                                  },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFAD510D),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : (_cameraController != null &&
                            _cameraController!.value.isInitialized)
                      ? CameraPreview(_cameraController!)
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFAD510D),
                          ),
                        ),
                ),
              ),
            ),

            // ==========================================
            // 🚀 AREA BAWAH (PANEL KONTROL UI)
            // ==========================================
            _imageFile == null
                ? _buildCameraControls() // Tampilan Kalau Lagi Mau Moto
                : _buildPreviewControls(), // Tampilan Kalau Udah Difoto
          ],
        ),
      ),
    );
  }

  // 📸 UI: PANEL BAWAH SAAT MAU MENGAMBIL FOTO
  Widget _buildCameraControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      // 🚀 Gak perlu warna background lagi, biar nyatu sama warna Scaffold (Coklat)
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 40), // Spacer penyeimbang
          // 🚀 TOMBOL JEPRET
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          // 🚀 TOMBOL PUTAR KAMERA
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // 🖼️ UI: PANEL BAWAH SAAT FOTO SUDAH DIAMBIL
  Widget _buildPreviewControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white, // Panel putih pas mau disave
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: _isUploading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFFAD510D)),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🚀 TOMBOL SIMPAN (UPLOAD)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _uploadGambar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAD510D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Bukti Pengantaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 🚀 TOMBOL AMBIL ULANG
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _imageFile = null);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFFAD510D),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ambil Ulang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAD510D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
