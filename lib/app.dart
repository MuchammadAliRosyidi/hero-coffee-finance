import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'screens/finance_dashboard_page.dart';
import 'screens/login_page.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class HeroCoffeeFinanceApp extends StatefulWidget {
  const HeroCoffeeFinanceApp({super.key});

  @override
  State<HeroCoffeeFinanceApp> createState() => _HeroCoffeeFinanceAppState();
}

class _HeroCoffeeFinanceAppState extends State<HeroCoffeeFinanceApp> {
  final AuthService _authService = const AuthService();
  AppUser? _currentUser;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await _authService.getSavedSession();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = user;
      _isBootstrapping = false;
    });
  }

  Future<void> _login(String username, String password) async {
    final user = await _authService.login(username, password);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username atau password salah')),
        );
      }
      return;
    }

    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hero Coffee Finance',
      theme: buildAppTheme(),
      home: _isBootstrapping
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _currentUser == null
              ? LoginPage(onLogin: _login)
              : FinanceDashboardPage(
                  user: _currentUser!,
                  onLogout: () {
                    _logout();
                  },
                ),
    );
  }
}
