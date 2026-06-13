// summary_model.dart
import 'package:flutter/material.dart';

class ProductModel {
  final String idProduk;
  final String nama;
  final String? deskripsi;
  final int terjual;
  final String imageUrl;
  final String? kategori;

  ProductModel({
    required this.idProduk,
    required this.nama,
    this.deskripsi,
    required this.terjual,
    required this.imageUrl,
    this.kategori,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      idProduk: (json['public_id'] ?? json['id_produk'] ?? '').toString(),
      nama: json['nama_produk'] ?? json['nama'] ?? 'Tanpa Nama',
      deskripsi: json['deskripsi'] ?? '',
      terjual: (json['jumlah_terjual'] ?? 0).toInt(),
      imageUrl: json['gambar'] ?? '',
      kategori: json['kategori'] ?? 'Umum',
    );
  }
}

class TransactionHistoryModel {
  final int idTransaksi;
  final String nomorInvoice;
  final String tanggalWaktu;
  final int subtotal;
  final int quantity;

  TransactionHistoryModel({
    required this.idTransaksi,
    required this.nomorInvoice,
    required this.tanggalWaktu,
    required this.subtotal,
    required this.quantity,
  });

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryModel(
      idTransaksi: (json['id_transaksi'] ?? 0).toInt(),
      nomorInvoice: json['nomor_invoice'] ?? '-',
      tanggalWaktu: json['tanggal_waktu'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toInt(),
      quantity: (json['quantity'] ?? 0).toInt(),
    );
  }
}

class DetailLaporanModel {
  final ProductModel produk;
  final int totalTerjual;
  final List<TransactionHistoryModel> riwayatTransaksi;

  DetailLaporanModel({required this.produk, required this.totalTerjual, required this.riwayatTransaksi});

  factory DetailLaporanModel.fromJson(Map<String, dynamic> json) {
    // 1. Ambil objek statistik_produk terlebih dahulu
    final statistik = json['statistik_produk'] ?? {};
    final riwayatRaw = json['riwayat_transaksi'] as List? ?? [];
    
    return DetailLaporanModel(
      produk: ProductModel.fromJson(json['produk']),
      // 2. Ambil total_terjual dari dalam objek statistik
      totalTerjual: (statistik['total_terjual'] ?? 0), 
      riwayatTransaksi: riwayatRaw.map((tx) => TransactionHistoryModel.fromJson(tx)).toList(),
    );
  }
}

class SummaryData {
  final double totalPendapatan;
  final double persentasePendapatan;
  final int totalTransaksi;
  final int persentaseTransaksi;
  final double rataRataPesanan;
  final String statusRataRata;
  final List<double> chartData;
  final List<String> chartLabels;
  final List<ProductModel> produkTerlaris;

  SummaryData({
    required this.totalPendapatan,
    required this.persentasePendapatan,
    required this.totalTransaksi,
    required this.persentaseTransaksi,
    required this.rataRataPesanan,
    required this.statusRataRata,
    required this.chartData,
    required this.chartLabels,
    required this.produkTerlaris,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    final header = json['header_statistik'] ?? {};
    final grafik = json['grafik_pendapatan'] as List? ?? [];
    final produk = json['produk_terlaris'] as List? ?? [];

    List<String> labels = [];
    List<double> values = [];
    for (var item in grafik) {
      labels.add(item['label'] ?? '');
      values.add((item['nilai'] ?? 0).toDouble());
    }

    return SummaryData(
      totalPendapatan: (header['total_pendapatan'] ?? 0).toDouble(),
      persentasePendapatan: (header['persentase_kenaikan_pendapatan'] ?? 0).toDouble(),
      totalTransaksi: (header['total_transaksi'] ?? 0).toInt(),
      persentaseTransaksi: (header['persentase_kenaikan_transaksi'] ?? 0).toInt(),
      rataRataPesanan: (header['rata_rata_pesanan'] ?? 0).toDouble(),
      statusRataRata: header['status_rata_rata'] ?? 'stabil',
      chartLabels: labels,
      chartData: values,
      produkTerlaris: produk.map((p) => ProductModel.fromJson(p)).toList(),
    );
  }
}