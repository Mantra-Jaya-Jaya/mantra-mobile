import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'widgets/map_picker_widget.dart';

class AlamatBaru extends StatefulWidget {
  const AlamatBaru({super.key});

  @override
  AlamatBaruState createState() => AlamatBaruState();
}

class AlamatBaruState extends State<AlamatBaru> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  final ProfileService _profileService = ProfileService();
  final GlobalKey<MapPickerWidgetState> _mapPickerKey = GlobalKey();

  bool _isFormValid = false;
  bool _isLoading = false;
  bool _showMapPicker = false;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();

    _labelController.addListener(_validateForm);
    _namaController.addListener(_validateForm);
    _teleponController.addListener(_validateForm);
    _alamatController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _labelController.text.isNotEmpty &&
          _namaController.text.isNotEmpty &&
          _teleponController.text.isNotEmpty &&
          _alamatController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: BaseHeaderWidget(
        title: 'Alamat Baru',

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Label Alamat",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _buildField("Contoh: Rumah / Kantor", _labelController),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEFEF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildInputRow(
                    Icons.person_outline,
                    "Nama Penerima",
                    _namaController,
                    "Aarav",
                  ),

                  const SizedBox(height: 15),

                  _buildInputRow(
                    Icons.phone_outlined,
                    "No. Telepon",
                    _teleponController,
                    "+62...",
                  ),

                  const SizedBox(height: 15),

                  _buildInputRow(
                    Icons.location_on_outlined,
                    "Alamat Lengkap",
                    _alamatController,
                    "Detail alamat...",
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Map Picker Toggle
            GestureDetector(
              onTap: () {
                setState(() => _showMapPicker = !_showMapPicker);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFEF),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _showMapPicker
                        ? const Color(0xFFAF510C)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      color: Color(0xFFAF510C),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedLat != null
                            ? '📍 Lokasi dipilih (${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)})'
                            : '📍 Pilih Lokasi di Peta',
                        style: TextStyle(
                          color: _selectedLat != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Icon(
                      _showMapPicker
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFFAF510C),
                    ),
                  ],
                ),
              ),
            ),

            if (_showMapPicker) ...[
              const SizedBox(height: 12),
              MapPickerWidget(
                key: _mapPickerKey,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAF510C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Konfirmasi Lokasi'),
                  onPressed: () {
                  final picker = _mapPickerKey.currentState;
                  if (picker != null) {
                    setState(() {
                      _selectedLat = picker.selectedLatitude;
                      _selectedLng = picker.selectedLongitude;
                      _showMapPicker = false;
                    });
                  }
                },
              ),
            ),
            ],

            const SizedBox(height: 20),

            // Catatan Lokasi
            const Text(
              "Catatan Lokasi (opsional)",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Contoh: Depan gang, samping masjid, dll.",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFAF510C)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFAF510C), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isFormValid && !_isLoading
                    ? () async {
                        setState(() => _isLoading = true);
                        try {
                          await _profileService.tambahAlamat(
                            label: _labelController.text,
                            nama: _namaController.text,
                            telepon: _teleponController.text,
                            alamatLengkap: _alamatController.text,
                            isUtama: false,
                            latitude: _selectedLat,
                            longitude: _selectedLng,
                            catatanLokasi: _catatanController.text,
                          );
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menambahkan alamat'),
                              ),
                            );
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAF510C),
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Simpan Alamat",
                        style: TextStyle(
                          color: _isFormValid ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFAF510C)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFAF510C), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildInputRow(
    IconData icon,
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFD8B08C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 5),

              TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFAF510C)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFAF510C)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
