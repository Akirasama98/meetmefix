class LecturerModel {
  final String id;
  final String name;
  final String title;
  final String department;
  final String photoUrl;
  final String status; // 'online', 'offline', 'busy'
  final String lastSeen; // Waktu terakhir online

  LecturerModel({
    required this.id,
    required this.name,
    required this.title,
    required this.department,
    required this.photoUrl,
    required this.status,
    required this.lastSeen,
  });

  // Konversi dari Firestore document ke LecturerModel
  factory LecturerModel.fromMap(Map<String, dynamic> map, String id) {
    return LecturerModel(
      id: id,
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      department: map['department'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      status: map['status'] ?? 'offline',
      lastSeen: map['lastSeen'] ?? '',
    );
  }

  // Konversi dari LecturerModel ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'department': department,
      'photoUrl': photoUrl,
      'status': status,
      'lastSeen': lastSeen,
    };
  }
}
