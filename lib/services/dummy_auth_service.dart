import '../models/user_model.dart';

class DummyAuthService {
  // Daftar akun dummy
  static final List<Map<String, dynamic>> _dummyAccounts = [
    // Akun mahasiswa
    {
      'id': 'student1',
      'email': 'mahasiswa@example.com',
      'password': 'password',
      'name': 'DWI RIFQI NOFRIANTO',
      'role': 'student',
      'nim': '232410102021',
      'department': 'Teknik Informatika',
      'faculty': 'Fakultas Ilmu Komputer',
      'phone': '+62 812-3456-7890',
      'photoUrl': 'https://randomuser.me/api/portraits/men/10.jpg',
    },
    {
      'id': 'student2',
      'email': 'ahmad@example.com',
      'password': 'password',
      'name': 'Ahmad Fauzi',
      'role': 'student',
      'nim': '232410102022',
      'department': 'Teknik Informatika',
      'faculty': 'Fakultas Ilmu Komputer',
      'phone': '+62 812-3456-7891',
      'photoUrl': 'https://randomuser.me/api/portraits/men/11.jpg',
    },
    {
      'id': 'student3',
      'email': 'siti@example.com',
      'password': 'password',
      'name': 'Siti Nurhaliza',
      'role': 'student',
      'nim': '232410102023',
      'department': 'Sistem Informasi',
      'faculty': 'Fakultas Ilmu Komputer',
      'phone': '+62 812-3456-7892',
      'photoUrl': 'https://randomuser.me/api/portraits/women/12.jpg',
    },
    
    // Akun dosen
    {
      'id': 'lecturer1',
      'email': 'dosen@example.com',
      'password': 'password',
      'name': 'DR. PRIZA PANDUNATA',
      'role': 'lecturer',
      'nip': '198201182008121002',
      'department': 'Teknik Informatika',
      'faculty': 'Fakultas Ilmu Komputer',
      'phone': '+62 812-3456-7893',
      'photoUrl': 'https://randomuser.me/api/portraits/men/1.jpg',
    },
    {
      'id': 'lecturer2',
      'email': 'dwi@example.com',
      'password': 'password',
      'name': 'DR. DWI WIJONARKO',
      'role': 'lecturer',
      'nip': '198201182008121003',
      'department': 'Teknik Informatika',
      'faculty': 'Fakultas Ilmu Komputer',
      'phone': '+62 812-3456-7894',
      'photoUrl': 'https://randomuser.me/api/portraits/men/2.jpg',
    },
    {
      'id': 'lecturer3',
      'email': 'budi@example.com',
      'password': 'password',
      'name': 'DR. BUDI SANTOSO',
      'role': 'lecturer',
      'nip': '198201182008121004',
      'department': 'Sistem Informasi',
      'faculty': 'Fakultas Ilmu Komputer',
      'phone': '+62 812-3456-7895',
      'photoUrl': 'https://randomuser.me/api/portraits/men/3.jpg',
    },
  ];

  // Mendapatkan user berdasarkan email dan password
  static UserModel? signIn(String email, String password) {
    try {
      final account = _dummyAccounts.firstWhere(
        (account) => account['email'] == email && account['password'] == password,
      );
      
      return UserModel.fromMap(account, account['id']);
    } catch (e) {
      return null;
    }
  }

  // Mendapatkan user berdasarkan role
  static List<UserModel> getUsersByRole(String role) {
    return _dummyAccounts
        .where((account) => account['role'] == role)
        .map((account) => UserModel.fromMap(account, account['id']))
        .toList();
  }

  // Mendapatkan user berdasarkan id
  static UserModel? getUserById(String id) {
    try {
      final account = _dummyAccounts.firstWhere(
        (account) => account['id'] == id,
      );
      
      return UserModel.fromMap(account, account['id']);
    } catch (e) {
      return null;
    }
  }
}
