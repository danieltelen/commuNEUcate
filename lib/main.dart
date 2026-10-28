import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'widgets/network_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xsehqejkzjnlhoniozxb.supabase.co',
    publishableKey: 'sb_publishable_uqT0sdPo5cwm-grSyI6-Ig_xphbjwCC',
  );

  runApp(const QRASApp());
}

class QRASApp extends StatelessWidget {
  const QRASApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CommNEUcate',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return NetworkWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1200) return child!;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07070E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C6AFF),
          secondary: Color(0xFF0FE0B0),
          surface: Color(0xFF111120),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF07070E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF111120),
          selectedItemColor: Color(0xFF7C6AFF),
          unselectedItemColor: Colors.grey,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF111120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0x1AFFFFFF)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
