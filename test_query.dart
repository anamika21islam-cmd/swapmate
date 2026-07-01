import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://qridchgklmajtmnyxcfn.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyaWRjaGdrbG1hanRtbnl4Y2ZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0OTA0MTUsImV4cCI6MjA5ODA2NjQxNX0.2dzbkmVgAk9kdPWAtt6Rm19GbsjughQoShOB5n0mXpk',
  );

  try {
    print('Fetching profiles...');
    final response = await supabase.from('profiles').select().limit(1);
    if (response.isNotEmpty) {
      print('Profile keys: ${response.first.keys.toList()}');
      print('Profile data: ${response.first}');
    } else {
      print('No profiles found');
    }
  } catch (e) {
    print('Query failed with error: $e');
  }
}
