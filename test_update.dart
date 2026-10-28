import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://yniynwcsrcmvuizkuiaf.supabase.co', 'sb_publishable_jwhVDgEEzBrDcEWwPP5XEw_sEu7SFBS');
  
  // Login
  final response = await supabase.auth.signInWithPassword(email: 'admin@admin.com', password: 'admin123');
  developer.log('Logged in: ${response.user?.email ?? 'none'}');

  // Fetch a pending report
  final reports = await supabase.from('reports').select().eq('status', 'pending_review').limit(1);
  if (reports.isEmpty) {
    developer.log('No pending reports found.');
    return;
  }
  
  final report = reports.first;
  developer.log('Found report: ${report['item_name']} ID: ${report['id']}');
  
  try {
    developer.log('Attempting to update status to approved...');
    final result = await supabase.from('reports').update({'status': 'approved'}).eq('id', report['id']).select();
    developer.log('Update Result: $result');
  } catch (e) {
    developer.log('Error: $e');
  }
}
