import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart'; // 🚀 WAJIB ADA: Buat nembak API Rute OSRM

// 🚀 IMPORT DIKEMBALIKAN SESUAI FILE ASLI LU
import '../../core/models/pengantaran_model.dart';
import '../../core/services/pengantaran_service.dart';
import '../../core/widgets/global_appbar_kurir.dart';
import '../orders/detail_pengantaran_kurir.dart';

class RutePengantaranPage extends StatefulWidget {
  final String idPengantaran;

  const RutePengantaranPage({super.key, required this.idPengantaran});

  @override
  State<RutePengantaranPage> createState() => _RutePengantaranPageState();
}

class _RutePengantaranPageState extends State<RutePengantaranPage> {
  final DetailPengantaranService _service = DetailPengantaranService();
  DetailPengantaranModel? _dataPengantaran;

  // ── MAP VARIABLES ──
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  Timer? _timerLokasi;

  // 🚀 PENAMPUNG GARIS RUTE
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initDataAndLocation();
  }

  // 🚀 ALUR BARU: Ambil Data -> Cek Lokasi -> Gambar Rute
  Future<void> _initDataAndLocation() async {
    // 1. Tarik data tujuan dari Backend
    final data = await _service.getDetailPengantaran(widget.idPengantaran);
    if (!mounted) return;
    setState(() {
      _dataPengantaran = data;
    });

    if (data == null) return;

    // 2. Minta izin dan ambil lokasi kurir
    var status = await Permission.location.request();
    if (status.isGranted) {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() {});

      // 3. Tarik Garis Rute (OSRM API)
      if (_currentPosition != null) {
        await _getRoute(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(data.tujuan.latitude, data.tujuan.longitude),
        );
      }

      // 4. Pantau pergerakan motor (Live Tracking)
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
              });
            }
          });

          _mulaiRadarGPS();
    }
  }

  // 🚀 2. FUNGSI RADAR REALTIME KE BACKEND
  void _mulaiRadarGPS() {
    _timerLokasi = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // Pastiin lokasinya gak kosong sebelum dikirim
      if (_currentPosition != null) {
        try {
          await _service.updateLokasiKurir(
            widget.idPengantaran,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
          debugPrint(
            '✅ Radar Backend Update: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
          );
        } catch (e) {
          debugPrint('❌ Gagal update radar: $e');
        }
      }
    });
  }

  // 🚀 FUNGSI SAKTI: Nembak API OSRM Buat Dapetin Titik-Titik Garis
  Future<void> _getRoute(LatLng start, LatLng end) async {
    try {
      final dio = Dio();
      // OSRM mintanya (Longitude, Latitude)
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> coords =
            data['routes'][0]['geometry']['coordinates'];

        setState(() {
          // Balikin lagi jadi (Latitude, Longitude) buat digambar di peta
          _routePoints = coords
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Gagal menarik rute OSRM: $e");
    }
  }

  @override
  void dispose() {
    _timerLokasi?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD510D),
      appBar: GlobalAppBarKurir(
        title: 'Rute Pengantaran',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        bottom: false,
        child: _dataPengantaran == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: Stack(
                        children: [
                          // ==========================================
                          // 🚀 LAYER 1: PETA + GARIS RUTE
                          // ==========================================
                          Positioned.fill(
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(
                                  _dataPengantaran!.tujuan.latitude,
                                  _dataPengantaran!.tujuan.longitude,
                                ),
                                initialZoom: 14.5,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.mantra.app',
                                ),

                                // 🚀 LAYER GARIS RUTE (Polyline)
                                PolylineLayer(
                                  polylines: [
                                    // 🚀 TAMBAHIN BARIS INI: Cek dulu rutenya udah ada isinya belum!
                                    if (_routePoints.isNotEmpty)
                                      Polyline(
                                        points: _routePoints,
                                        strokeWidth: 5.0,
                                        color: Colors.blueAccent,
                                      ),
                                  ],
                                ),

                                // 🚀 LAYER PIN & MOTOR
                                MarkerLayer(
                                  markers: [
                                    // 📍 Marker Customer
                                    Marker(
                                      point: LatLng(
                                        _dataPengantaran!.tujuan.latitude,
                                        _dataPengantaran!.tujuan.longitude,
                                      ),
                                      width: 50,
                                      height: 50,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 45,
                                      ),
                                    ),
                                    // 🛵 Marker Kurir
                                    if (_currentPosition != null)
                                      Marker(
                                        point: LatLng(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                        ),
                                        width: 50,
                                        height: 50,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.two_wheeler,
                                            color: Colors.blue,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ==========================================
                          // 🚀 LAYER 2: BOTTOM SHEET
                          // ==========================================
                          DraggableScrollableSheet(
                            initialChildSize: 0.45,
                            minChildSize: 0.12,
                            maxChildSize: 0.45,
                            builder:
                                (
                                  BuildContext context,
                                  ScrollController scrollController,
                                ) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFAD510D),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(30),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 20,
                                          offset: Offset(0, -5),
                                        ),
                                      ],
                                    ),
                                    child: SingleChildScrollView(
                                      controller: scrollController,
                                      padding: const EdgeInsets.only(
                                        left: 24,
                                        right: 24,
                                        top: 12,
                                        bottom: 40,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Center(
                                            child: Container(
                                              width: 50,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          Text(
                                            'ORDER ID',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _dataPengantaran!.idPengantaran
                                                .split('-')
                                                .first
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Tujuan Pengantaran',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      _dataPengantaran!
                                                          .penerima
                                                          .nama,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _dataPengantaran!
                                                          .tujuan
                                                          .alamatLengkap,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white
                                                            .withOpacity(0.8),
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 32),

                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DetailPesananPage(
                                                          idPengantaran: widget.idPengantaran,
                                                          isSedangDiantar: true, 
                                                          isDariPeta: true,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Lihat Selengkapnya',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
