import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_identity/theme/app_theme.dart';
import 'package:qr_identity/widgets/bottom_nav_bar.dart';
import 'package:qr_identity/models/user_profile.dart';
import 'package:qr_identity/pages/history_page.dart';
import 'package:qr_identity/pages/my_qr_page.dart';
import 'package:qr_identity/pages/registration_page.dart';
import 'package:qr_identity/pages/scanner_page.dart';
import 'package:qr_identity/services/prefs_service.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Identity',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const _StartupDecider(),
    );
  }
}

class _StartupDecider extends StatefulWidget {
  const _StartupDecider();

  @override
  State<_StartupDecider> createState() => _StartupDeciderState();
}

class _StartupDeciderState extends State<_StartupDecider> {
  int _currentIndex = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await PrefsService.getProfile();
    setState(() {
      _profile = profile;
      if (_profile != null) {
        _currentIndex = 1; // Switch to My QR tab if profile exists
      }
    });
  }

  List<Widget> get _pages => [
        const RegistrationPage(),
        const MyQrPage(),
        const ScannerPage(),
        const HistoryPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_profile != null || index == 0) {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }
}
