import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'messages';

  // Mendapatkan pesan antara dua pengguna
  Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    return _firestore
        .collection(_collection)
        .where('senderId', whereIn: [userId1, userId2])
        .where('receiverId', whereIn: [userId1, userId2])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Mengirim pesan baru
  Future<String> sendMessage(MessageModel message) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_collection).add(message.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Menandai pesan sebagai telah dibaca
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan jumlah pesan yang belum dibaca
  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
