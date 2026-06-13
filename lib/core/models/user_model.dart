class UserModel {
  final int idUser;          // Diubah ke int (sesuai int64 di Go)
  final String publicId;     // Menampung public_id dari middleware
  final String username;
  final String email;
  final String namaLengkap;
  final String role;
  final String? profileId;
  final String? fotoProfil;

  UserModel({
    required this.idUser,
    required this.publicId,
    required this.username,
    required this.email,
    required this.namaLengkap,
    required this.role,
    this.profileId,
    this.fotoProfil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Konversi aman untuk idUser (int64 di Go -> int di Dart)
      idUser: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      
      // Mengambil publicId dari context middleware
      publicId: (json['public_id'] ?? '').toString(),
      
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      namaLengkap: (json['nama_lengkap'] ?? json['nama'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      profileId: json['profile_id']?.toString(),
      fotoProfil: json['foto_profil']?.toString(),
    );
  }
}