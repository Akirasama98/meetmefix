import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/dummy_auth_service.dart';

class DummyAuthProvider with ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userModel != null;

  // Inisialisasi provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tidak ada inisialisasi otomatis untuk dummy auth
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login dengan email dan password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gunakan DummyAuthService untuk login
      UserModel? user = DummyAuthService.signIn(email, password);
      
      if (user != null) {
        _userModel = user;
        return true;
      } else {
        _error = 'Email atau password salah';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login sebagai dosen
  Future<bool> signInAsLecturer(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gunakan DummyAuthService untuk login
      UserModel? user = DummyAuthService.signIn(email, password);
      
      if (user != null && user.role == 'lecturer') {
        _userModel = user;
        return true;
      } else {
        _error = 'Email atau password salah, atau akun bukan dosen';
        return false;
      }
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
      // Untuk dummy auth, cukup set _userModel ke null
      _userModel = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mendapatkan daftar dosen
  List<UserModel> getLecturers() {
    return DummyAuthService.getUsersByRole('lecturer');
  }

  // Mendapatkan daftar mahasiswa
  List<UserModel> getStudents() {
    return DummyAuthService.getUsersByRole('student');
  }

  // Mendapatkan user berdasarkan id
  UserModel? getUserById(String id) {
    return DummyAuthService.getUserById(id);
  }
}
