import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://sscapdzdcbsptccfwvpf.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzY2FwZHpkY2JzcHRjY2Z3dnBmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDY4OTEsImV4cCI6MjA5MzQ4Mjg5MX0.ZFrwL1SG05HAzXFujSePVi2RDKHhBGEh3d6lPbWrdNg'
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
