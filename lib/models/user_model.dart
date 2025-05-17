import 'lecturer_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' atau 'lecturer'
  final String? nim; // Nomor Induk Mahasiswa (untuk student)
  final String? nip; // Nomor Induk Pegawai (untuk lecturer)
  final String? department;
  final String? faculty;
  final String? phone;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.nip,
    this.department,
    this.faculty,
    this.phone,
    this.photoUrl,
  });

  // Konversi dari Firestore document ke UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      nim: map['nim'],
      nip: map['nip'],
      department: map['department'],
      faculty: map['faculty'],
      phone: map['phone'],
      photoUrl: map['photoUrl'],
    );
  }

  // Konversi dari UserModel ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'nim': nim,
      'nip': nip,
      'department': department,
      'faculty': faculty,
      'phone': phone,
      'photoUrl': photoUrl,
    };
  }

  // Konversi dari UserModel ke LecturerModel
  LecturerModel toLecturerModel() {
    return LecturerModel(
      id: id,
      name: name,
      title: role == 'lecturer' ? 'Dosen' : 'Mahasiswa',
      department: department ?? '',
      photoUrl: photoUrl ?? '',
      status: 'offline', // Default status
      lastSeen: 'Tidak diketahui',
    );
  }
}
