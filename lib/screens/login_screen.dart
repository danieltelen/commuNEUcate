import 'package:flutter/material.dart';
import '../utils/toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_layout.dart';
import 'admin_layout.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && mounted) {
        try {
          String? avatarUrl = session.user.userMetadata?['avatar_url'] ?? session.user.userMetadata?['picture'];
          if (avatarUrl != null && avatarUrl.contains('googleusercontent.com') && avatarUrl.contains('=')) {
            avatarUrl = '${avatarUrl.split('=').first}=s1024';
          }
          
          final fullName = session.user.userMetadata?['full_name'] ?? session.user.userMetadata?['name'];

          if (avatarUrl != null || fullName != null) {
            await Supabase.instance.client.from('profiles').update({
              'avatar_url': ?avatarUrl,
              'full_name': ?fullName,
            }).eq('id', session.user.id);
          }
        } catch (e) {
          debugPrint('Error syncing profile: $e');
        }

        // Fetch user role from profiles table
        try {
          final profile = await Supabase.instance.client
              .from('profiles')
              .select('role, account_status')
              .eq('id', session.user.id)
              .maybeSingle();

          if (mounted) {
            final role = profile?['role'] ?? 'user';
            final accountStatus = profile?['account_status'] ?? 'pending';
            if (role != 'admin' && accountStatus != 'approved') {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                final message = accountStatus == 'denied'
                    ? 'Your account was not approved. Contact an administrator.'
                    : 'Your account is waiting for administrator approval.';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
              }
              return;
            }

            showTopToast(context, 'Welcome back!');
            if (role == 'admin') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLayout()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainLayout()));
            }
          }
        } catch (e) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not verify your account. Please try again.')),
            );
          }
        }
      }
    });
  }

  Future<void> _doGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.qras://login-callback/',
        queryParams: {
          'hd': 'neu.edu.ph', // Suggests Google to only show NEU accounts
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-in Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both email and password')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section matching HTML
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF060612), Color(0xFF10102A), Color(0xFF060F1A)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x337C6AFF), Color(0x1F0FE0B0)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x597C6AFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2E7C6AFF),
                          blurRadius: 40,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.lock_outline, color: Color(0xFFA99BFF), size: 36),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CommNEUcate',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lost & Found — Report and recover\nyour items securely',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            // Form section
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('EMAIL ADDRESS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: const Color(0xFF111120),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C6AFF))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('PASSWORD', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: const Color(0xFF111120),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C6AFF))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _doLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('New here? Create an account with email'),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white10)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: TextStyle(color: Colors.grey))),
                      Expanded(child: Divider(color: Colors.white10)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Google Sign In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _doGoogleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_circle, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Sign in with NEU Google', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
