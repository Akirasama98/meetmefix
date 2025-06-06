import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/integrated_login_screen.dart';
import 'screens/lecturer_list_screen.dart';
import 'screens/lecturer/lecturer_main_screen.dart';
import 'providers/auth_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'services/schedule_notification_service.dart';
import 'services/schedule_status_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // For debug builds, use debug provider
    // For production, use: AndroidProvider.playIntegrity, AppleProvider.deviceCheck
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification services
  await NotificationService.initialize();
  await ScheduleNotificationService.initialize();

  // Initialize schedule status service
  await ScheduleStatusService.initialize();

  // Check and request notification permissions
  await ScheduleNotificationService.checkAndRequestPermissions();

  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyAppContent(),
    );
  }
}

class MyAppContent extends StatefulWidget {
  const MyAppContent({super.key});

  @override
  State<MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<MyAppContent> {
  @override
  void initState() {
    super.initState();
    // Inisialisasi AuthProvider setelah build selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isInitialized) {
        authProvider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bimbingan Akademik',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5BBFCB),
            ),
            useMaterial3: true,
            // Tambahkan pengaturan untuk text scaling
            textTheme: Typography.material2018().black.apply(
              fontSizeFactor: 1.0,
              fontSizeDelta: 0.0,
            ),
          ),
          // Tambahkan dukungan lokalisasi
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Daftar bahasa yang didukung
          supportedLocales: const [
            Locale('id', 'ID'), // Indonesia
            Locale('en', 'US'), // English
          ],
          // Gunakan bahasa Indonesia sebagai default
          locale: const Locale('id', 'ID'),
          // Tambahkan builder untuk mengontrol text scaling
          builder: (context, child) {
            // Pastikan text scaling tidak terlalu besar
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // Define routes
          routes: {'/lecturer_list': (context) => const LecturerListScreen()},
          // Tampilkan layar login saat pertama kali dibuka, tapi tetap bisa navigasi ke home setelah login
          home:
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : authProvider.isAuthenticated
                  ? _getHomeScreenByRole(authProvider)
                  : const ResponsiveWrapper(child: IntegratedLoginScreen()),
        );
      },
    );
  }

  // Menentukan layar home berdasarkan role user
  Widget _getHomeScreenByRole(AuthProvider authProvider) {
    if (authProvider.userModel?.role == 'lecturer') {
      return const LecturerMainScreen();
    } else {
      return const MainScreen();
    }
  }
}

// Widget wrapper untuk membuat aplikasi responsif
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Dapatkan ukuran layar
    final size = MediaQuery.of(context).size;

    // Jika layar cukup besar (tablet/desktop), batasi lebar maksimum
    if (size.width > 600) {
      return Center(
        child: SizedBox(
          width: 600, // Lebar maksimum untuk tablet
          child: child,
        ),
      );
    }

    // Untuk layar kecil (smartphone), gunakan seluruh layar
    return child;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Kembali ke tab home (indeks 0)

  static final List<Widget> _screens = [
    const HomeScreen(),
    const ScheduleScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Janji',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// LecturerMainScreen is now imported from screens/lecturer/lecturer_main_screen.dart
