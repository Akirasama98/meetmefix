import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/firestore_user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userModel != null;
  User? get currentUser => _authService.currentUser;
  bool get isInitialized => _isInitialized;

  // Inisialisasi provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Auto login dihapus untuk menghindari crash
      // User harus login secara manual setiap kali aplikasi dibuka
    } catch (e) {
      _error = _handleGenericError(e);
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Login dengan email dan password (untuk mahasiswa dan dosen)
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Login dengan Firebase Auth
      UserCredential userCredential = await _authService
          .signInWithEmailAndPassword(email, password);

      // Ambil data user dari Firestore
      final userData = await _authService.getUserData(userCredential.user!.uid);

      if (userData != null) {
        // Konversi dari FirestoreUserModel ke UserModel
        _userModel = UserModel(
          id: userData.id,
          name: userData.name,
          email: userData.email,
          role: userData.role,
          nim: userData.nim,
          nip: userData.nip,
          department: userData.department,
          faculty: userData.faculty,
          phone: userData.phone,
          photoUrl: userData.photoUrl,
        );
        // Dapatkan dan simpan token FCM
        String? token = await NotificationService.getToken();
        await NotificationService.saveTokenToDatabase(_userModel!.id, token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Data pengguna tidak ditemukan';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      // Debug print untuk membantu troubleshooting
      print('FIREBASE AUTH ERROR: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          _error = 'Email tidak terdaftar. Silakan periksa kembali email Anda.';
          break;
        case 'wrong-password':
          _error = 'Password yang Anda masukkan salah. Silakan coba lagi.';
          break;
        case 'invalid-email':
          _error = 'Format email tidak valid. Masukkan email yang benar.';
          break;
        case 'user-disabled':
          _error =
              'Akun ini telah dinonaktifkan. Silakan hubungi administrator.';
          break;
        case 'too-many-requests':
          _error =
              'Terlalu banyak percobaan login yang gagal. Silakan coba lagi nanti.';
          break;
        case 'operation-not-allowed':
          _error =
              'Login dengan email dan password tidak diizinkan. Hubungi administrator.';
          break;
        case 'network-request-failed':
          _error =
              'Koneksi internet terputus. Periksa koneksi Anda dan coba lagi.';
          break;
        case 'invalid-credential':
          _error = 'Kredensial yang digunakan tidak valid. Silakan coba lagi.';
          break;
        case 'account-exists-with-different-credential':
          _error = 'Akun sudah ada dengan kredensial yang berbeda.';
          break;
        default:
          _error = 'Login gagal: ${e.message}';
      }

      // Pastikan isLoading diatur ke false dan UI diperbarui
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _handleGenericError(e);

      // Pastikan isLoading diatur ke false dan UI diperbarui
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _userModel = null;
    } catch (e) {
      _error = _handleGenericError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mendapatkan daftar dosen
  Future<List<UserModel>> getLecturers() async {
    try {
      final lecturers = await _authService.getLecturers();
      return lecturers
          .map(
            (lecturer) => UserModel(
              id: lecturer.id,
              name: lecturer.name,
              email: lecturer.email,
              role: lecturer.role,
              nim: lecturer.nim,
              nip: lecturer.nip,
              department: lecturer.department,
              faculty: lecturer.faculty,
              phone: lecturer.phone,
              photoUrl: lecturer.photoUrl,
            ),
          )
          .toList();
    } catch (e) {
      _error = _handleGenericError(e);
      return [];
    }
  }

  // Mendapatkan daftar mahasiswa
  Future<List<UserModel>> getStudents() async {
    try {
      final students = await _authService.getStudents();
      return students
          .map(
            (student) => UserModel(
              id: student.id,
              name: student.name,
              email: student.email,
              role: student.role,
              nim: student.nim,
              nip: student.nip,
              department: student.department,
              faculty: student.faculty,
              phone: student.phone,
              photoUrl: student.photoUrl,
            ),
          )
          .toList();
    } catch (e) {
      _error = _handleGenericError(e);
      return [];
    }
  }

  // Mendapatkan user berdasarkan id
  Future<UserModel?> getUserById(String id) async {
    try {
      final userData = await _authService.getUserData(id);
      if (userData != null) {
        return UserModel(
          id: userData.id,
          name: userData.name,
          email: userData.email,
          role: userData.role,
          nim: userData.nim,
          nip: userData.nip,
          department: userData.department,
          faculty: userData.faculty,
          phone: userData.phone,
          photoUrl: userData.photoUrl,
        );
      }
      return null;
    } catch (e) {
      _error = _handleGenericError(e);
      return null;
    }
  }

  // Upload profile image as Base64 string
  Future<String?> uploadProfileImage(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_userModel == null || _userModel!.id.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Use StorageService to convert image to Base64
      final storageService = StorageService();
      final base64Image = await storageService.uploadProfilePhoto(imageFile);

      return base64Image;
    } catch (e) {
      _error = _handleGenericError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile in Firestore
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_userModel == null || _userModel!.id.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Convert UserModel to FirestoreUserModel
      final firestoreUser = FirestoreUserModel(
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        role: updatedUser.role,
        nim: updatedUser.nim,
        nip: updatedUser.nip,
        department: updatedUser.department,
        faculty: updatedUser.faculty,
        phone: updatedUser.phone,
        photoUrl: updatedUser.photoUrl,
      );

      // Update user data in Firestore
      await _authService.updateUserData(firestoreUser);

      // Update local user model
      _userModel = updatedUser;

      return true;
    } catch (e) {
      _error = _handleGenericError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method untuk menangani error umum
  String _handleGenericError(dynamic error) {
    if (error is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    } else if (error is FirebaseException) {
      return 'Terjadi kesalahan: ${error.message ?? "Unknown Firebase Error"}';
    } else if (error is Exception) {
      String errorMessage = error.toString();
      // Hapus "Exception: " dari awal pesan error jika ada
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }
      return errorMessage;
    } else {
      return 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
    }
  }
}
