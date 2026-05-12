import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/roles/role.dart';
import '../../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../../features/fan/presentation/screens/fan_dashboard.dart';
import '../../../features/fantasy/presentation/screens/fantasy_dashboard.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  UserRole selectedRole = UserRole.fan;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Biometric
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isBiometricSupported = false;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _checkSavedCredentials();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _isBiometricSupported = isAvailable && isDeviceSupported;
      });
    } catch (e) {
      setState(() {
        _isBiometricSupported = false;
      });
    }
  }

  Future<void> _checkSavedCredentials() async {
    final email = await _secureStorage.read(key: 'user_email');
    final password = await _secureStorage.read(key: 'user_password');
    setState(() {
      _hasSavedCredentials = email != null && password != null;
    });
  }

  Future<void> _saveCredentials(String email, String password) async {
    await _secureStorage.write(key: 'user_email', value: email);
    await _secureStorage.write(key: 'user_password', value: password);
    setState(() {
      _hasSavedCredentials = true;
    });
  }

  Future<void> _loginWithBiometric() async {
    if (!_isBiometricSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasSavedCredentials) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login with email/password first to enable fingerprint login'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to login to Pitch Premier',
      );

      if (authenticated && mounted) {
        final email = await _secureStorage.read(key: 'user_email');
        final password = await _secureStorage.read(key: 'user_password');
        
        if (email != null && password != null) {
          _emailController.text = email;
          _passwordController.text = password;
          await _handleAuth();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF171717), Color(0xFF0D7377)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_soccer, size: 80, color: Color(0xFF14FFEC)),
                    const SizedBox(height: 16),
                    Text('PITCH PREMIER', style: GoogleFonts.bebasNeue(fontSize: 48, color: Colors.white, letterSpacing: 4)),
                    const SizedBox(height: 4),
                    Text('Your football universe', style: GoogleFonts.inter(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              prefixIcon: const Icon(Icons.email, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          
                          if (_isBiometricSupported)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _loginWithBiometric,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF14FFEC).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: const Color(0xFF14FFEC).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.fingerprint, color: Color(0xFF14FFEC), size: 24),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Login with Fingerprint',
                                            style: TextStyle(color: const Color(0xFF14FFEC), fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                                },
                                child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF14FFEC), fontSize: 12)),
                              ),
                            ),
                          if (!isLogin) ...[
                            const SizedBox(height: 12),
                            const Text('SELECT ROLE', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: UserRole.values.map((role) => ChoiceChip(
                                label: Text(role.label),
                                selected: selectedRole == role,
                                onSelected: (_) => setState(() => selectedRole = role),
                                selectedColor: role.color.withValues(alpha: 0.2),
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                labelStyle: TextStyle(color: selectedRole == role ? role.color : Colors.white70),
                              )).toList(),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF14FFEC),
                                foregroundColor: Colors.black,
                              ),
                              child: _isLoading 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                                  : Text(isLogin ? 'SIGN IN' : 'CREATE ACCOUNT'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() { 
                              isLogin = !isLogin; 
                              _emailController.clear(); 
                              _passwordController.clear(); 
                            }),
                            child: Text(
                              isLogin ? "Don't have an account? Register" : "Already have an account? Sign in", 
                              style: const TextStyle(color: Colors.white70)
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!mounted) return;
    
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        if (response.user != null && mounted) {
          await _saveCredentials(_emailController.text.trim(), _passwordController.text.trim());
          
          String userRole = 'fan';
          try {
            final profileData = await Supabase.instance.client
                .from('profiles')
                .select('role')
                .eq('id', response.user!.id)
                .single();
            userRole = profileData['role'] ?? 'fan';
          } catch (e) {}
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Welcome back!'), backgroundColor: Colors.green)
            );
            
            if (userRole == 'admin') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
            } else if (userRole == 'fantasyManager') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FantasyDashboard()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FanDashboard()));
            }
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials'), backgroundColor: Colors.red)
          );
        }
      } else {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        if (response.user != null && mounted) {
          try {
            await Supabase.instance.client
                .from('profiles')
                .upsert({
                  'id': response.user!.id,
                  'email': _emailController.text.trim(),
                  'role': selectedRole.name,
                });
          } catch (e) {}
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created! You can now login.'), backgroundColor: Colors.green)
            );
            setState(() {
              isLogin = true;
              _passwordController.clear();
            });
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up failed. Try again.'), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid credentials'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
