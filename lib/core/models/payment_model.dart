// ============================================================
// models/payment_models.dart
// ============================================================

class VarianProduk {
  final int idSpesifikasiBarang;
  final String label;
  final int hargaBarang;
  final int hargaDiskon;
  final int stok;

  VarianProduk({
    required this.idSpesifikasiBarang,
    required this.label,
    required this.hargaBarang,
    required this.hargaDiskon,
    required this.stok,
  });

  factory VarianProduk.fromJson(Map<String, dynamic> json) {
    return VarianProduk(
      idSpesifikasiBarang: json['id_spesifikasi_barang'] ?? 0,
      label: json['label'] ?? '',
      hargaBarang: json['harga_barang'] ?? 0,
      hargaDiskon: json['harga_diskon'] ?? 0,
      stok: json['stok'] ?? 0,
    );
  }
}

class HasilCariProduk {
  final int idBarang;
  final String namaBarang;
  final String? gambarBarang;
  final List<VarianProduk> varian;

  HasilCariProduk({
    required this.idBarang,
    required this.namaBarang,
    this.gambarBarang,
    required this.varian,
  });

  factory HasilCariProduk.fromJson(Map<String, dynamic> json) {
    return HasilCariProduk(
      idBarang: json['id_barang'] ?? 0,
      namaBarang: json['nama_barang'] ?? '',
      gambarBarang: json['gambar_barang'],
      varian: (json['varian'] as List<dynamic>? ?? [])
          .map((v) => VarianProduk.fromJson(v))
          .toList(),
    );
  }
}

/// Item yang sudah masuk ke keranjang kasir
class ItemKeranjang {
  final int idPesanan;
  final int idSpesifikasiBarang;
  final String namaProduk;
  final String labelVarian;
  final int hargaSatuan;
  int jumlah;

  ItemKeranjang({
    required this.idPesanan,
    required this.idSpesifikasiBarang,
    required this.namaProduk,
    required this.labelVarian,
    required this.hargaSatuan,
    required this.jumlah,
  });

  int get subtotal => hargaSatuan * jumlah;
}

class RingkasanCheckout {
  final int idOrder;
  final String publicId;
  final String nomorOrder;
  final List<ItemCheckout> items;
  final int subtotal;
  final int pajakNominal;
  final int totalAkhir;

  RingkasanCheckout({
    required this.idOrder,
    required this.publicId,
    required this.nomorOrder,
    required this.items,
    required this.subtotal,
    required this.pajakNominal,
    required this.totalAkhir,
  });

  factory RingkasanCheckout.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final orderInfo = data['order_info'];
    final biaya = data['ringkasan_biaya'];
    return RingkasanCheckout(
      idOrder: orderInfo['id_order'] ?? 0,
      publicId: orderInfo['public_id'] ?? '',
      nomorOrder: orderInfo['nomor_order'] ?? '',
      items: (data['item_checkout'] as List<dynamic>? ?? [])
          .map((i) => ItemCheckout.fromJson(i))
          .toList(),
      subtotal: biaya['subtotal'] ?? 0,
      pajakNominal: biaya['pajak_nominal'] ?? 0,
      totalAkhir: biaya['total_akhir'] ?? 0,
    );
  }
}

class ItemCheckout {
  final String namaProduk;
  final String varian;
  final int qty;
  final int totalPerItem;

  ItemCheckout({
    required this.namaProduk,
    required this.varian,
    required this.qty,
    required this.totalPerItem,
  });

  factory ItemCheckout.fromJson(Map<String, dynamic> json) {
    return ItemCheckout(
      namaProduk: json['nama_produk'] ?? '',
      varian: json['varian'] ?? '',
      qty: json['qty'] ?? 0,
      totalPerItem: json['total_per_item'] ?? 0,
    );
  }
}

class HasilBayarTunai {
  final int kembalian;
  final String nomorInvoice;
  final String urlPrintStruk;

  HasilBayarTunai({
    required this.kembalian,
    required this.nomorInvoice,
    required this.urlPrintStruk,
  });

  factory HasilBayarTunai.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final invoice = data['invoice'];
    return HasilBayarTunai(
      kembalian: data['kembalian'] ?? 0,
      nomorInvoice: invoice['nomor_invoice'] ?? '',
      urlPrintStruk: invoice['url_print_struk'] ?? '',
    );
  }
}

class HasilBayarNonTunai {
  final String orderId;
  final String metode;
  final String? qrUrl;
  final String? vaNumber;

  HasilBayarNonTunai({
    required this.orderId,
    required this.metode,
    this.qrUrl,
    this.vaNumber,
  });

  factory HasilBayarNonTunai.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return HasilBayarNonTunai(
      orderId: data['order_id'] ?? '',
      metode: data['metode'] ?? '',
      qrUrl: data['qr_url'],
      vaNumber: data['va_number'],
    );
  }
}


class HasilCekStatus {
  final bool isLunas;
  final String statusTransaksi;

  HasilCekStatus({required this.isLunas, required this.statusTransaksi});

  factory HasilCekStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return HasilCekStatus(
      isLunas: json['is_lunas'] ?? false,
      statusTransaksi: data['status_transaksi'] ?? 'pending',
    );
  }
}
