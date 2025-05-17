import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';
import '../models/lecturer_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan ID pengguna saat ini
  String? get currentUserId => _auth.currentUser?.uid;

  // Mendapatkan daftar dosen
  Stream<List<LecturerModel>> getLecturers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'lecturer')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LecturerModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Mendapatkan daftar mahasiswa (untuk dosen)
  Stream<List<UserModel>> getStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Mendapatkan daftar chat (untuk tampilan daftar chat)
  Stream<List<Map<String, dynamic>>> getChatList() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((chatSnapshot) async {
          List<Map<String, dynamic>> chatList = [];

          for (var chatDoc in chatSnapshot.docs) {
            final chatData = chatDoc.data();
            final participants = List<String>.from(
              chatData['participants'] ?? [],
            );

            // Dapatkan ID partner chat (bukan user saat ini)
            final partnerId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );

            if (partnerId.isEmpty) continue;

            // Dapatkan data partner
            final partnerDoc =
                await _firestore.collection('users').doc(partnerId).get();
            if (!partnerDoc.exists) continue;

            final partnerData = partnerDoc.data() ?? {};

            // Dapatkan pesan terakhir
            final lastMessageQuery =
                await _firestore
                    .collection('chats')
                    .doc(chatDoc.id)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();

            Map<String, dynamic>? lastMessage;
            if (lastMessageQuery.docs.isNotEmpty) {
              lastMessage = lastMessageQuery.docs.first.data();
              lastMessage['id'] = lastMessageQuery.docs.first.id;
            }

            chatList.add({
              'chatId': chatDoc.id,
              'partnerId': partnerId,
              'partnerName': partnerData['name'] ?? 'Unknown',
              'partnerPhotoUrl': partnerData['photoUrl'] ?? '',
              'partnerRole': partnerData['role'] ?? '',
              'partnerNim': partnerData['nim'] ?? '',
              'partnerDepartment': partnerData['department'] ?? '',
              'lastMessage': lastMessage,
              'unreadCount': await _getUnreadCount(chatDoc.id, currentUserId!),
            });
          }

          // Urutkan berdasarkan waktu pesan terakhir
          chatList.sort((a, b) {
            final aLastMessage = a['lastMessage'];
            final bLastMessage = b['lastMessage'];

            if (aLastMessage == null) return 1;
            if (bLastMessage == null) return -1;

            final aTimestamp = aLastMessage['timestamp'] as int? ?? 0;
            final bTimestamp = bLastMessage['timestamp'] as int? ?? 0;

            return bTimestamp.compareTo(aTimestamp);
          });

          return chatList;
        });
  }

  // Mendapatkan jumlah pesan yang belum dibaca
  Future<int> _getUnreadCount(String chatId, String userId) async {
    final querySnapshot =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .where('receiverId', isEqualTo: userId)
            .get();

    return querySnapshot.docs.length;
  }

  // Mendapatkan atau membuat chat room
  Future<String> getOrCreateChatRoom(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Cek apakah chat room sudah ada
    final querySnapshot =
        await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .get();

    for (var doc in querySnapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Buat chat room baru jika belum ada
    final docRef = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Mendapatkan pesan dalam chat room
  Stream<List<ChatMessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessageModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Mengirim pesan
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String message,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'receiverId': receiverId,
          'message': message,
          'timestamp': timestamp,
          'isRead': false,
        });
  }

  // Menandai pesan sebagai sudah dibaca
  Future<void> markAsRead(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Menandai semua pesan sebagai sudah dibaca
  Future<void> markAllAsRead(String chatId) async {
    if (currentUserId == null) return;

    final querySnapshot =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .where('receiverId', isEqualTo: currentUserId)
            .get();

    final batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Update status online/offline
  Future<void> updateUserStatus(bool isOnline) async {
    if (currentUserId == null) return;

    final now = DateTime.now();
    final lastSeen = '${now.hour}:${now.minute}';

    await _firestore.collection('users').doc(currentUserId).update({
      'status': isOnline ? 'online' : 'offline',
      'lastSeen': isOnline ? 'Online' : lastSeen,
    });
  }
}
