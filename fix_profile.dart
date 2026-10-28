import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://yniynwcsrcmvuizkuiaf.supabase.co', 'sb_publishable_jwhVDgEEzBrDcEWwPP5XEw_sEu7SFBS');
  
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
