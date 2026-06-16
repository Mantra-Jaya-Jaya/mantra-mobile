class UserModel {
  final int idUser;
  final String publicId;
  final String username;
  final String email;
  final String namaLengkap;
  final String role;
  final String? profileId;
  final String? fotoProfil;
  final String noTelp;
  final String alamat;

  UserModel({
    required this.idUser,
    required this.username,
    required this.email,
    required this.namaLengkap,
    required this.role,
    this.profileId,
    this.fotoProfil,
    this.noTelp = '',
    this.alamat = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: int.tryParse((json['id_user'] ?? json['user_id'] ?? '0').toString()) ?? 0,
      publicId: (json['public_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      namaLengkap: (json['nama_lengkap'] ?? json['nama'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      profileId: json['profile_id']?.toString(),
      fotoProfil: json['foto_profil']?.toString(),
      noTelp: (json['no_telp'] ?? '').toString(),
      alamat: (json['alamat'] ?? '').toString(),
    );
  }
}
