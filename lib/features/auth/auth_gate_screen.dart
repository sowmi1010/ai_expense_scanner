import 'package:flutter/material.dart';

import '../../data/services/auth_local_service.dart';
import '../shell/shell_screen.dart';
import 'auth_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final AuthLocalService _authService = AuthLocalService();

  bool _isCheckingSession = true;
  String? _loggedInUserName;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final loggedIn = await _authService.isLoggedIn();
    final user = await _authService.getRegisteredUser();

    if (!mounted) return;

    setState(() {
      _loggedInUserName = loggedIn ? user?.name : null;
      _isCheckingSession = false;
    });
  }

  void _handleSignedIn(String userName) {
    setState(() => _loggedInUserName = userName);
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();

    if (!mounted) return;

    setState(() => _loggedInUserName = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _loggedInUserName;

    if (userName != null && userName.trim().isNotEmpty) {
      return ShellScreen(
        userName: userName,
        onLogout: _handleLogout,
      );
    }

    return AuthScreen(
      authService: _authService,
      onSignedIn: _handleSignedIn,
    );
  }
}
