class ProfilKurirModel {
  final int idKurir;
  final int idUser;
  final String publicId;
  final String userPublicId;
  final String namaLengkap;
  final String username;
  final String email;
  final String noTelp;
  final String jenisKelamin;
  final String tempatLahir;
  final String tanggalLahir;
  final String alamat;
  final String pendidikanTerakhir;
  final String nik;
  final String fotoProfil;

  ProfilKurirModel({
    required this.idKurir,
    required this.idUser,
    required this.publicId,
    required this.userPublicId,
    required this.namaLengkap,
    required this.username,
    required this.email,
    required this.noTelp,
    required this.jenisKelamin,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.alamat,
    required this.pendidikanTerakhir,
    required this.nik,
    required this.fotoProfil,
  });

  factory ProfilKurirModel.fromJson(Map<String, dynamic> json) {
    return ProfilKurirModel(
      idKurir: json['id_kurir'] ?? 0,
      idUser: json['id_user'] ?? 0,
      publicId: json['public_id'] ?? '',
      userPublicId: json['user_public_id'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? 'Kurir',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      noTelp: json['no_telp'] ?? '',
      jenisKelamin: json['jenis_kelamin'] ?? '',
      tempatLahir: json['tempat_lahir'] ?? '',
      tanggalLahir: json['tanggal_lahir'] ?? '',
      alamat: json['alamat'] ?? '',
      pendidikanTerakhir: json['pendidikan_terakhir'] ?? '',
      nik: json['nik'] ?? '',
      fotoProfil: json['foto_profil'] ?? '',
    );
  }

  // 🚀 FUNGSI SAKTI BUAT NGAMBIL KATA PERTAMA (TETAP DIPERTAHANKAN)
  String get namaPanggilan {
    if (namaLengkap.isEmpty) return 'Kurir';
    return namaLengkap.split(' ')[0];
  }
}
