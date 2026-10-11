import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testQuery() async {
  try {
    final supabase = Supabase.instance.client;
    // Test with integer
    final resInt = await supabase.from('messages').select().limit(1);
    developer.log('Int result: $resInt');
  } catch (e) {
    developer.log('Error: $e');
  }
}
