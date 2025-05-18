import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/firestore_user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userModel != null;
  User? get currentUser => _authService.currentUser;

  // Inisialisasi provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cek apakah ada user yang sudah login
      User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Ambil data user dari Firestore
        final userData = await _authService.getUserData(currentUser.uid);
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
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
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
        return true;
      } else {
        _error = 'Data pengguna tidak ditemukan';
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _error = 'Email tidak terdaftar';
      } else if (e.code == 'wrong-password') {
        _error = 'Password salah';
      } else if (e.code == 'invalid-email') {
        _error = 'Format email tidak valid';
      } else {
        _error = 'Login gagal: ${e.message}';
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      _error = e.toString();
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
      _error = e.toString();
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
      _error = e.toString();
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
      _error = e.toString();
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
      _error = e.toString();
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
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
