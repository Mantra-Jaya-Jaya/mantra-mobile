import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerWidget> createState() => MapPickerWidgetState();
}

class MapPickerWidgetState extends State<MapPickerWidget> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isLoadingLocation = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _isLoadingLocation = false;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    var status = await Permission.location.request();
    if (!(status.isGranted || status.isLimited)) {
      setState(() {
        _isLoadingLocation = false;
        _errorMessage = 'Izin lokasi tidak diberikan. Ketuk peta untuk memilih lokasi.';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      _mapController.move(_selectedLocation!, 15.0);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _errorMessage = 'Gagal mendeteksi lokasi. Ketuk peta untuk memilih.';
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.map_outlined, size: 18, color: Color(0xFFAF510C)),
            const SizedBox(width: 6),
            const Text(
              'Pilih Lokasi di Peta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            if (_selectedLocation != null)
              GestureDetector(
                onTap: _getCurrentLocation,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, size: 16, color: Color(0xFFAF510C)),
                    SizedBox(width: 4),
                    Text(
                      'GPS',
                      style: TextStyle(
                        color: Color(0xFFAF510C),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFAF510C)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFAF510C)))
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ?? const LatLng(-7.0514, 110.4381),
                        initialZoom: 15.0,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.mantra.jayajaya',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (_errorMessage != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _getCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xFFAF510C),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (_selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '📍 ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ),
      ],
    );
  }

  double? get selectedLatitude => _selectedLocation?.latitude;
  double? get selectedLongitude => _selectedLocation?.longitude;
}
