import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget untuk menampilkan icon metode pembayaran.
///
/// Mendukung dua format icon dari backend:
/// 1. URL (http/https) → gambar (PNG/JPG atau SVG). Jika gagal, fallback ke Material icon.
/// 2. Material icon name string (misal: "package_outlined", "qr_code_scanner")
///    → ditampilkan langsung sebagai Material [Icon].
class PaymentIconWidget extends StatelessWidget {
  final String iconValue;
  final double size;
  final Color? color;

  const PaymentIconWidget({
    super.key,
    required this.iconValue,
    this.size = 28,
    this.color,
  });

  /// Mapping dari nama string Material icon ke [IconData].
  static const Map<String, IconData> _materialIconMap = {
    'package_outlined': Icons.inventory_2_outlined,
    'qr_code_scanner': Icons.qr_code_scanner,
    'payments_outlined': Icons.payments_outlined,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'money': Icons.money,
    'local_atm': Icons.local_atm,
  };

  static const IconData _defaultIcon = Icons.payment;

  bool get _isUrl =>
      iconValue.startsWith('http://') || iconValue.startsWith('https://');

  bool get _isSvg => iconValue.toLowerCase().endsWith('.svg');

  IconData get _materialIcon => _materialIconMap[iconValue] ?? _defaultIcon;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? const Color(0xFFAD510D);

    if (!_isUrl) {
      return Icon(_materialIcon, size: size, color: iconColor);
    }

    if (_isSvg) {
      return SvgPicture.network(
        iconValue,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Icon(_defaultIcon, size: size, color: iconColor),
      );
    }

    return Image.network(
      iconValue,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(_defaultIcon, size: size, color: iconColor),
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: iconColor,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}
