import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'lecturer/lecturer_main_screen.dart' as lecturer_main_screen;

class IntegratedLoginScreen extends StatefulWidget {
  const IntegratedLoginScreen({super.key});

  @override
  State<IntegratedLoginScreen> createState() => _IntegratedLoginScreenState();
}

class _IntegratedLoginScreenState extends State<IntegratedLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Remove this initialization since we're now doing it in the main app
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<AuthProvider>(context, listen: false).initialize();
    // });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        // Panggil signIn dan tunggu hasilnya
        bool success = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Pastikan widget masih terpasang sebelum melanjutkan
        if (!mounted) return;

        // Jika login berhasil, navigasi ke halaman yang sesuai
        if (success) {
          // Navigasi ke halaman yang sesuai berdasarkan role
          if (authProvider.userModel?.role == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else if (authProvider.userModel?.role == 'lecturer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        const lecturer_main_screen.LecturerMainScreen(),
              ),
            );
          }
        } else {
          // Jika login gagal, tampilkan pesan error
          _showErrorMessage(authProvider.error ?? 'Login gagal');
        }
      } catch (e) {
        // Tangkap error yang mungkin terjadi selama proses login
        if (!mounted) return;
        _showErrorMessage('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  // Method untuk menampilkan pesan error
  void _showErrorMessage(String message) {
    // Debug print untuk membantu troubleshooting
    print('LOGIN ERROR: $message');

    // Pastikan pesan error ditampilkan di UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Hapus snackbar yang mungkin sedang ditampilkan
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 30),
                  _buildLoginButton(),
                  const SizedBox(height: 40),
                  _buildCopyright(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App logo
        Image.asset(
          'assets/images/apk.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        const Text(
          'MEETME',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aplikasi Bimbingan Akademik',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF5BBFCB),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Masukkan email Anda',
        prefixIcon: const Icon(Icons.email, color: Color(0xFF5BBFCB)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF5BBFCB), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email tidak boleh kosong';
        }
        if (!value.contains('@')) {
          return 'Email tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Masukkan password Anda',
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF5BBFCB)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF5BBFCB), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password tidak boleh kosong';
        }
        if (value.length < 6) {
          return 'Password minimal 6 karakter';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    // Gunakan Consumer untuk memastikan widget diperbarui saat isLoading berubah
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final bool isLoading = authProvider.isLoading;

        return ElevatedButton(
          onPressed: isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5BBFCB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            disabledBackgroundColor: const Color(0xFF5BBFCB).withAlpha(150),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Masuk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
        );
      },
    );
  }

  Widget _buildCopyright() {
    return Column(
      children: [
        const Divider(color: Colors.grey, thickness: 0.5),
        const SizedBox(height: 10),
        Text(
          'versi 1.0.0',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
