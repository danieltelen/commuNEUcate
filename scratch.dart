import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://yniynwcsrcmvuizkuiaf.supabase.co',
    'sb_publishable_jwhVDgEEzBrDcEWwPP5XEw_sEu7SFBS'
  );
  
  await supabase.auth.signInWithPassword(email: 'admin@admin.com', password: 'admin123');
  
  try {
    final profile = await supabase.from('profiles').select('id').neq('role', 'admin').limit(1).single();
    final studentId = profile['id'];
    
    final manualAlerts = await supabase
        .from('messages')
        .select('*')
        .eq('receiver_id', studentId)
        .ilike('content', '%SYSTEM_ALERT%')
        .order('created_at', ascending: false);
        
    developer.log('Found ${manualAlerts.length} system alerts using ilike.');
    
    for (var msg in manualAlerts) {
      developer.log('MSG: ${msg['content']}');
    }
  } catch (e) {
    developer.log('Failed: $e');
  }
}
