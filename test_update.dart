import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://sscapdzdcbsptccfwvpf.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzY2FwZHpkY2JzcHRjY2Z3dnBmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDY4OTEsImV4cCI6MjA5MzQ4Mjg5MX0.ZFrwL1SG05HAzXFujSePVi2RDKHhBGEh3d6lPbWrdNg');
  
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
