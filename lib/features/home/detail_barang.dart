import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/home/services/katalog_service.dart';
import 'package:frontend/features/home/services/cart_service.dart';
import 'package:frontend/core/widgets/base_header_widget.dart';
import 'package:frontend/features/cart/checkout.dart';
import 'package:dio/dio.dart';

class DetailBarangPage extends StatefulWidget {
  final BarangModel barang;

  const DetailBarangPage({super.key, required this.barang});

  @override
  State<DetailBarangPage> createState() => _DetailBarangPageState();
}

class _DetailBarangPageState extends State<DetailBarangPage> {
  // Simpan pilihan varian per jenis spesifikasi (misal: {'Warna': varianMerah, 'Ukuran': varian20})
  Map<String, VarianModel> selectedVarians = {};
  late Future<BarangModel> _detailFuture;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _detailFuture = KatalogService().getDetailBarang(widget.barang.idBarang);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return FutureBuilder<BarangModel>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: BaseHeaderWidget(
              title: 'Detail Barang',
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFAD510D)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: BaseHeaderWidget(title: 'Detail Barang'),
            body: Center(child: Text('Terjadi kesalahan: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData) {
          final detailBarang = snapshot.data!;

          // Kelompokkan varian berdasarkan nama spesifikasinya
          final Map<String, List<VarianModel>> groupedVarians = {};
          for (var v in detailBarang.varian) {
            groupedVarians.putIfAbsent(v.namaSpesifikasi, () => []).add(v);
          }

          // Otomatis pilih varian dinonaktifkan sesuai request (pengguna harus klik sendiri)

          // Hitung total harga dari semua varian yang dipilih
          int currentPrice = 0;
          int originalPrice = 0;
          int currentStok = 0;

          if (selectedVarians.isNotEmpty) {
            bool first = true;
            selectedVarians.forEach((key, v) {
              currentPrice += detailBarang.punyaDiskon
                  ? v.hargaDiskon
                  : v.hargaBarang;
              originalPrice += v.hargaBarang;

              // Untuk stok, kita ambil nilai minimum dari semua varian yang dipilih
              if (first) {
                currentStok = v.stok;
                first = false;
              } else {
                if (v.stok < currentStok) {
                  currentStok = v.stok;
                }
              }
            });
          } else {
            // Tampilkan harga terendah jika belum ada yang dipilih
            currentPrice = detailBarang.hargaTerendah;
            originalPrice = detailBarang.hargaTerendah;
            currentStok = int.tryParse(detailBarang.stok) ?? 0;
          }

          final bool allVariansSelected =
              groupedVarians.isEmpty ||
              (selectedVarians.length == groupedVarians.length);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: BaseHeaderWidget(
              title: 'Detail Barang',
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Gambar Produk
                  Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey.shade100,
                    child: detailBarang.gambarBarang.isNotEmpty
                        ? Image.network(
                            detailBarang.gambarBarang,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama & Harga
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                detailBarang.namaBarang,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              currencyFormat.format(currentPrice),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFAD510D),
                              ),
                            ),
                          ],
                        ),
                        if (detailBarang.punyaDiskon &&
                            originalPrice > currentPrice) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              currencyFormat.format(originalPrice),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Stok Barang
                        Row(
                          children: [
                            const Icon(
                              Icons.shelves,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stok: $currentStok pcs',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, thickness: 1),

                        // Loop untuk setiap jenis spesifikasi
                        ...groupedVarians.entries.map((entry) {
                          final String rawNamaSpek = entry.key;
                          final List<VarianModel> listVarian = entry.value;

                          // Kapitalisasi huruf pertama
                          final String namaSpek = rawNamaSpek.isNotEmpty
                              ? rawNamaSpek[0].toUpperCase() +
                                    rawNamaSpek.substring(1)
                              : rawNamaSpek;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$namaSpek',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: listVarian.map((v) {
                                  final isSelected =
                                      selectedVarians[rawNamaSpek]?.idVarian ==
                                      v.idVarian;
                                  final bool isOutOfStock = v.stok <= 0;

                                  return ChoiceChip(
                                    label: Text(
                                      isOutOfStock
                                          ? '${v.namaDetail} (Habis)'
                                          : v.namaDetail,
                                    ),
                                    selected: isSelected,
                                    onSelected: isOutOfStock
                                        ? null
                                        : (selected) {
                                            setState(() {
                                              if (selected) {
                                                selectedVarians[rawNamaSpek] =
                                                    v;
                                              } else {
                                                selectedVarians.remove(
                                                  rawNamaSpek,
                                                );
                                              }
                                            });
                                          },
                                    selectedColor: const Color(
                                      0xFFAD510D,
                                    ).withOpacity(0.15),
                                    backgroundColor: isOutOfStock
                                        ? Colors.grey.shade200
                                        : Colors.grey.shade50,
                                    labelStyle: TextStyle(
                                      color: isOutOfStock
                                          ? Colors.grey
                                          : (isSelected
                                                ? const Color(0xFFAD510D)
                                                : Colors.black87),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFFAD510D)
                                            : (isOutOfStock
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade300),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    showCheckmark: false,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),

                        if (groupedVarians.isNotEmpty)
                          const Divider(height: 16, thickness: 1),

                        // Deskripsi
                        const Text(
                          'Deskripsi Produk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detailBarang.deskripsi.isNotEmpty
                              ? detailBarang.deskripsi
                              : 'Tidak ada deskripsi tersedia untuk produk ini.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allVariansSelected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: detailBarang.gambarBarang.isNotEmpty
                              ? Image.network(
                                  detailBarang.gambarBarang,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detailBarang.namaBarang,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (selectedVarians.isNotEmpty)
                                Text(
                                  selectedVarians.values
                                      .map((v) => v.namaDetail)
                                      .join(', '),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  quantity > 1
                                      ? () => setState(() => quantity--)
                                      : null,
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Color(0xFFAD510D),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  quantity < currentStok
                                      ? () => setState(() => quantity++)
                                      : null,
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFFAD510D),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            // Validasi: Semua jenis spesifikasi harus dipilih
                            if (selectedVarians.length <
                                groupedVarians.length) {
                              final List<String> belumDipilih = [];
                              groupedVarians.keys.forEach((key) {
                                if (!selectedVarians.containsKey(key)) {
                                  belumDipilih.add(
                                    key.isNotEmpty
                                        ? key[0].toUpperCase() +
                                              key.substring(1)
                                        : key,
                                  );
                                }
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Silakan pilih ${belumDipilih.join(", ")} terlebih dahulu',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange.shade800,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            try {
                              final cartService = CartService();
                              final List<String> namaDipilih = [];

                              // Tambahkan semua varian yang dipilih ke keranjang secara berurutan
                              for (var v in selectedVarians.values) {
                                if (v.idVarian == 0) {
                                  throw Exception(
                                    "ID Varian tidak valid untuk ${v.namaDetail}",
                                  );
                                }

                                await cartService.addToCart(
                                  idBarang: detailBarang.idBarang,
                                  quantity: quantity,
                                  idVarian: v.idVarian,
                                );
                                namaDipilih.add(v.namaDetail);
                              }

                              if (context.mounted) {
                                // Pop up notifikasi berhasil (tanpa tombol OK, hilang otomatis)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Barang dimasukkan ke keranjang!',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              String errorMsg =
                                  "Gagal menambahkan ke keranjang";
                              if (e is DioException) {
                                errorMsg =
                                    e.response?.data['message'] ??
                                    e.message ??
                                    errorMsg;
                              } else if (e is Exception) {
                                errorMsg = e.toString();
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFAD510D),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Color(0xFFAD510D),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (!allVariansSelected) {
                                final List<String> belumDipilih = [];
                                groupedVarians.keys.forEach((key) {
                                  if (!selectedVarians.containsKey(key)) {
                                    belumDipilih.add(
                                      key.isNotEmpty
                                          ? key[0].toUpperCase() +
                                                key.substring(1)
                                          : key,
                                    );
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Silakan pilih ${belumDipilih.join(", ")} terlebih dahulu',
                                    ),
                                    backgroundColor: Colors.orange.shade800,
                                  ),
                                );
                                return;
                              }

                              // Ambil ID varian (spesifikasi_barang) yang dipilih
                              // Jika produk punya varian, ambil dari pilihan user. 
                              // Jika tidak (Default), ambil idVarian pertama.
                              final int idVarianFinal = selectedVarians.isNotEmpty
                                  ? selectedVarians.values.first.idVarian
                                  : (detailBarang.varian.isNotEmpty ? detailBarang.varian.first.idVarian : 0);

                              // Navigasi ke halaman Checkout
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => Checkout(
                                        selectedProducts: [
                                          {
                                            'id': idVarianFinal, // Menggunakan ID Varian (SKU)
                                            'title': detailBarang.namaBarang,
                                            'subtitle':
                                                selectedVarians.isNotEmpty
                                                    ? selectedVarians.values
                                                        .map((v) => v.namaDetail)
                                                        .join(', ')
                                                    : (detailBarang.varian.isNotEmpty ? detailBarang.varian.first.namaDetail : 'Default'),
                                            'price': currentPrice,
                                            'quantity': quantity,
                                            'image': detailBarang.gambarBarang,
                                          },
                                        ],
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAD510D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Beli Sekarang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Scaffold(
          body: Center(child: Text('Data tidak ditemukan')),
        );
      },
    );
  }
}
