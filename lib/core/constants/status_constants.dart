/// Status constants untuk mapping ID status ke nama status
/// ID ini harus sinkron dengan database backend (tabel status_pesanan)
class StatusConstants {
  // Status IDs - DO NOT CHANGE
  static const int draft = 1;
  static const int menungguPembayaran = 2;
  static const int diproses = 3;
  static const int dikemas = 4;
  static const int dikirim = 5;
  static const int selesai = 6;
  static const int dibatalkan = 7;

  /// Get status name from ID
  static String getName(int? id) {
    switch (id) {
      case draft:
        return 'Draft';
      case menungguPembayaran:
        return 'Menunggu Pembayaran';
      case diproses:
        return 'Diproses';
      case dikemas:
        return 'Dikemas';
      case dikirim:
        return 'Dikirim';
      case selesai:
        return 'Selesai';
      case dibatalkan:
        return 'Dibatalkan';
      default:
        return 'Unknown';
    }
  }

  /// Get status display name (shorter version for UI)
  static String getDisplayName(int? id) {
    switch (id) {
      case draft:
        return 'Draft';
      case menungguPembayaran:
        return 'Menunggu';
      case diproses:
        return 'Diproses';
      case dikemas:
        return 'Dikemas';
      case dikirim:
        return 'Dikirim';
      case selesai:
        return 'Selesai';
      case dibatalkan:
        return 'Dibatalkan';
      default:
        return 'Unknown';
    }
  }

  /// Tipe pesanan constants
class TipePesananConstants {
  static const int online = 1;
  static const int offline = 2;

  static String getName(int? id) {
    switch (id) {
      case online:
        return 'Online';
      case offline:
        return 'Offline';
      default:
        return 'Unknown';
    }
  }
}

/// Check if status is online (requires kurir action)
  static bool isOnlineStatus(int? id) {
    return id == diproses || id == dikemas || id == dikirim;
  }

  /// Check if status is completed
  static bool isCompleted(int? id) {
    return id == selesai;
  }

  /// Check if status is cancelled
  static bool isCancelled(int? id) {
    return id == dibatalkan;
  }

  /// Check if status is pending payment
  static bool isPendingPayment(int? id) {
    return id == menungguPembayaran;
  }

  /// Get status color for UI
  static String getColor(int? id) {
    switch (id) {
      case draft:
        return 'grey';
      case menungguPembayaran:
        return 'orange';
      case diproses:
        return 'blue';
      case dikemas:
        return 'purple';
      case dikirim:
        return 'teal';
      case selesai:
        return 'green';
      case dibatalkan:
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get all status options (for dropdown/filter)
  static List<Map<String, dynamic>> getAllStatuses() {
    return [
      {'id': draft, 'name': 'Draft'},
      {'id': menungguPembayaran, 'name': 'Menunggu Pembayaran'},
      {'id': diproses, 'name': 'Diproses'},
      {'id': dikemas, 'name': 'Dikemas'},
      {'id': dikirim, 'name': 'Dikirim'},
      {'id': selesai, 'name': 'Selesai'},
      {'id': dibatalkan, 'name': 'Dibatalkan'},
    ];
  }
}
