import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://sscapdzdcbsptccfwvpf.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzY2FwZHpkY2JzcHRjY2Z3dnBmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDY4OTEsImV4cCI6MjA5MzQ4Mjg5MX0.ZFrwL1SG05HAzXFujSePVi2RDKHhBGEh3d6lPbWrdNg');
  

  final res = await supabase.auth.signInWithPassword(email: 'admin@admin.com', password: 'admin123');
  
  try {
    developer.log('Inserting test profile...');
    final result = await supabase.from('profiles').upsert({
      'id': res.user!.id,
      'email': res.user!.email ?? 'unknown',
      'role': 'user'
    }).select();
    developer.log('Success: $result');
  } catch (e) {
    developer.log('Error: $e');
  }
}
