import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://yniynwcsrcmvuizkuiaf.supabase.co', 'sb_publishable_jwhVDgEEzBrDcEWwPP5XEw_sEu7SFBS');
  

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
