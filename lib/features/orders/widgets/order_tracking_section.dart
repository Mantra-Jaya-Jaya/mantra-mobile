// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/api_error.dart';
import '../services/customer_order_service.dart';

class OrderTrackingSection extends StatefulWidget {
  final String noPesanan;
  const OrderTrackingSection({super.key, required this.noPesanan});

  @override
  OrderTrackingSectionState createState() => OrderTrackingSectionState();
}

class OrderTrackingSectionState extends State<OrderTrackingSection> {
  final CustomerOrderService _orderService = CustomerOrderService();

  bool _isLoading = true;
  String? _errorCode;
  String? _errorMessage;
  Map<String, dynamic>? _trackingData;
  Map<String, dynamic>? _biteshipStatus;
  Timer? _pollingTimer;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> refresh() => _fetchTracking();

  Future<void> _fetchTracking() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorCode = null;
        _errorMessage = null;
      });
    }

    try {
      final data = await _orderService.getTrackingInfo(widget.noPesanan);
      
      Map<String, dynamic>? newBiteshipStatus;
      final nomorResi = data['nomor_resi']?.toString() ?? data['waybill_id']?.toString() ?? '';
      
      if (nomorResi.startsWith('MOCK-BITE-')) {
        newBiteshipStatus = {
          'status': 'confirmed',
          'waybill_id': nomorResi,
          'ekspedisi': data['ekspedisi'] ?? 'Ekspedisi (Sandbox)',
        };
      } else if (nomorResi.isNotEmpty) {
        try {
          newBiteshipStatus = await _orderService.getBiteshipOrderStatus(widget.noPesanan);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _trackingData = data;
        if (newBiteshipStatus != null) {
          _biteshipStatus = newBiteshipStatus;
        }
        _isLoading = false;
      });
      _startPolling();
      _updateMapPosition();
    } on DioException catch (e) {
      if (!mounted) return;
      final apiError = ApiError.fromDioException(e);
      debugPrint(
        'Tracking load failed for ${widget.noPesanan}: '
        'status=${e.response?.statusCode}, code=${apiError.code}, '
        'message=${apiError.message}, data=${e.response?.data}',
      );
      setState(() {
        _errorCode = apiError.code;
        _errorMessage = apiError.userMessage;
        _isLoading = false;
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      debugPrint(
        'Tracking format failed for ${widget.noPesanan}: ${e.message}',
      );
      setState(() {
        _errorCode = null;
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Tracking load unexpected error for ${widget.noPesanan}: $e');
      setState(() {
        _errorCode = null;
        _errorMessage = 'Gagal memuat tracking pesanan';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollingTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => _backgroundFetch(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _backgroundFetch() async {
    try {
      final data = await _orderService.getTrackingInfo(widget.noPesanan);
      if (!mounted) return;
      setState(() {
        _trackingData = data;
      });
      _updateMapPosition();
    } catch (_) {
      // silently fail on background refresh
    }
  }

  void _updateMapPosition() {
    final lokasi = _asMap(_trackingData?['lokasi_kurir']);
    final lat = _asDouble(lokasi?['latitude']);
    final lng = _asDouble(lokasi?['longitude']);

    final lokasiTujuan = _asMap(_trackingData?['lokasi_tujuan']);
    final destLat = _asDouble(lokasiTujuan?['latitude']);
    final destLng = _asDouble(lokasiTujuan?['longitude']);

    if (lat != null && lng != null) {
      if (destLat != null && destLng != null && _routePoints.isEmpty) {
        _getRoute(LatLng(lat, lng), LatLng(destLat, destLng));
      }

      try {
        _mapController.move(LatLng(lat, lng), 15);
      } catch (e) {
        // Map controller might not be attached yet, which is fine since initialCenter will handle it.
      }
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    try {
      final dio = Dio();
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> coords =
            data['routes'][0]['geometry']['coordinates'];

        if (mounted) {
          setState(() {
            _routePoints = coords
                .map((c) => LatLng(c[1] as double, c[0] as double))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal menarik rute OSRM: $e");
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // _checkBiteshipStatus removed, integrated into refresh

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFAD510D)),
              ),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: Color(0xFFAD510D)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tracking Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            IconButton(
              onPressed: _fetchTracking,
              icon: const Icon(Icons.refresh, color: Color(0xFFAD510D)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
        if (_errorCode == 'AUTH_002') ...[
          const SizedBox(height: 8),
          const Text(
            'Pastikan Anda login dengan akun yang membuat pesanan ini.',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _fetchTracking,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFAD510D),
              side: const BorderSide(color: Color(0xFFAD510D)),
            ),
            child: const Text('Coba Lagi'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final data = _trackingData ?? <String, dynamic>{};
    final tipeEkspedisi = (data['tipe_ekspedisi'] ?? 'internal').toString();
    final kurir = data['kurir'];

    // Belum ada data kurir internal → show waiting state
    final noTrackingData = tipeEkspedisi == 'internal' && kurir == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: Color(0xFFAD510D)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tracking Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (tipeEkspedisi != 'internal')
              IconButton(
                onPressed: _isLoading ? null : _fetchTracking,
                icon: const Icon(Icons.refresh, color: Color(0xFFAD510D)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (noTrackingData)
          _buildWaitingState()
        else ...[
          if (tipeEkspedisi == 'internal')
            _buildInternalTracking(data)
          else
            _buildExternalTracking(data),
        ],
      ],
    );
  }

  Widget _buildWaitingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.orange[700]),
          const SizedBox(height: 12),
          const Text(
            'Pesanan Sedang Dikemas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pesanan Anda sedang dipersiapkan.\n'
            'Kurir akan segera ditugaskan setelah barang siap.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }


  Widget _buildInternalTracking(Map<String, dynamic> data) {
    final kurir = _asMap(data['kurir']);
    final lokasi = _asMap(data['lokasi_kurir']);
    final latitude = _asDouble(lokasi?['latitude']);
    final longitude = _asDouble(lokasi?['longitude']);

    final lokasiTujuan = _asMap(data['lokasi_tujuan']);
    final destLat = _asDouble(lokasiTujuan?['latitude']);
    final destLng = _asDouble(lokasiTujuan?['longitude']);

    final jarakMeter = _asInt(data['jarak_meter']);
    final estimasiTiba = (data['estimasi_tiba'] ?? '').toString();

    final hasValidLocation = latitude != null && longitude != null &&
        !(latitude == 0 && longitude == 0);
    final mapLat = hasValidLocation ? latitude : (destLat ?? -6.2088);
    final mapLng = hasValidLocation ? longitude : (destLng ?? 106.8456);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMapCard(
          mapLat,
          mapLng,
          destLat: destLat,
          destLng: destLng,
          showWaitingOverlay: !hasValidLocation,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Informasi Kurir',
          children: [
            _buildKeyValue('Nama', _stringValue(kurir?['nama'], fallback: '-')),
            if (_stringValue(kurir?['plat_nomor']).isNotEmpty)
              _buildKeyValue('Plat nomor', _stringValue(kurir?['plat_nomor'])),
            if (_stringValue(kurir?['foto']).isNotEmpty)
              _buildKeyValue('Foto profil', 'Tersedia'),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Estimasi Perjalanan',
          children: [
            _buildKeyValue(
              'Jarak',
              jarakMeter != null && jarakMeter > 0
                  ? _formatDistance(jarakMeter)
                  : '-',
            ),
            _buildKeyValue(
              'Estimasi tiba',
              estimasiTiba.isNotEmpty ? estimasiTiba : '-',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExternalTracking(Map<String, dynamic> data) {
    var history = _asListMap(data['history']);
    final nomorResi = _stringValue(
      _biteshipStatus?['waybill_id'] ??
          data['nomor_resi'] ??
          data['waybill_id'],
      fallback: '-',
    );
    final ekspedisi = _stringValue(
      _biteshipStatus?['ekspedisi'] ?? data['ekspedisi'],
      fallback: '-',
    );
    final statusBiteship = _stringValue(
      _biteshipStatus?['status'],
      fallback: 'pending',
    );

    final alamatTujuan = _stringValue(
      data['lokasi_tujuan']?['alamat_lengkap'] ??
          data['tujuan_pengantaran']?['alamat_lengkap'],
      fallback: 'alamat penerima',
    );

    if (nomorResi.startsWith('MOCK-BITE-')) {
      history = [
        {
          'status': 'On Delivery',
          'deskripsi': 'Paket sedang diantar dari Toko Mantra menuju $alamatTujuan.',
          'waktu': 'Baru saja'
        },
        {
          'status': 'Picked Up',
          'deskripsi': 'Paket telah diambil dari Toko Mantra.',
          'waktu': 'Beberapa saat lalu'
        }
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: 'Nomor Resi',
          children: [
            SelectableText(
              nomorResi,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Ekspedisi',
          children: [
            _buildKeyValue('Nama', ekspedisi),
            _buildKeyValue('Status', statusBiteship),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Icon(Icons.timeline, color: Color(0xFFAD510D)),
            SizedBox(width: 8),
            Text(
              'Riwayat Tracking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          _buildEmptyCard(
            icon: Icons.hourglass_empty,
            title: 'Riwayat belum tersedia',
            subtitle: 'Status pengiriman masih pending atau belum ada update dari ekspedisi.',
            actionLabel: null,
            action: null,
          )
        else
          Column(
            children: [
              ...history.map((item) => _buildTimelineItem(item)),
            ],
          ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFAD510D),
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 42, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stringValue(item['status'], fallback: '-'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (_stringValue(item['deskripsi']).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _stringValue(item['deskripsi']),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                if (_stringValue(item['waktu']).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _stringValue(item['waktu']),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(double latitude, double longitude, {double? destLat, double? destLng, bool showWaitingOverlay = false}) {
    List<Marker> markers = [
      Marker(
        point: LatLng(latitude, longitude),
        width: 50,
        height: 50,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4),
            ],
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.blue,
            size: 30,
          ),
        ),
      ),
    ];

    if (destLat != null && destLng != null && destLat != 0 && destLng != 0) {
      markers.add(
        Marker(
          point: LatLng(destLat, destLng),
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              key: const ValueKey('tracking-map'),
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mantra.app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blueAccent,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: markers,
                ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  showWaitingOverlay
                      ? 'Menunggu lokasi kurir...'
                      : 'Lokasi kurir realtime',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildKeyValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? action,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFAD510D)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (actionLabel != null && action != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: action,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFAD510D),
                  side: const BorderSide(color: Color(0xFFAD510D)),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<Map<String, dynamic>> _asListMap(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }
}
