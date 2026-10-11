import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://sscapdzdcbsptccfwvpf.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzY2FwZHpkY2JzcHRjY2Z3dnBmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDY4OTEsImV4cCI6MjA5MzQ4Mjg5MX0.ZFrwL1SG05HAzXFujSePVi2RDKHhBGEh3d6lPbWrdNg');
  
  // Login as admin to get permissions
  await supabase.auth.signInWithPassword(email: 'admin@admin.com', password: 'admin123');
  
  try {
    // Just insert the missing profile using the ID from the screenshot
    await supabase.from('profiles').insert({
      'id': 'b90bf588-1616-422f-9cce-c91796063589',
      'email': 'habibiy@example.com', // Fake email just to satisfy the constraint
      'role': 'user',
    });
    developer.log('Successfully inserted profile for Habibiy!');
  } catch (e) {
    developer.log('Error or already exists: $e');
  }
}
