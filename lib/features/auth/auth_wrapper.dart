import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // KEEP THIS - it's used
import '../admin/presentation/screens/admin_dashboard.dart';
import '../fan/presentation/screens/fan_dashboard.dart';
import '../fantasy/presentation/screens/fantasy_dashboard.dart';
import '../presentation/screens/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      final session =
          Supabase.instance.client.auth.currentSession; // THIS USES THE IMPORT

      if (session != null && mounted) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .single();

        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userRole = response['role'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF14FFEC)),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const LoginScreen();
    }

    switch (_userRole) {
      case 'admin':
        return const AdminDashboard();
      case 'fantasyManager':
        return const FantasyDashboard();
      case 'fan':
      default:
        return const FanDashboard();
    }
  }
}
