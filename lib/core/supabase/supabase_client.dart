import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _url = 'https://pnodgxlvhjnrkcbvipmy.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBub2RneGx2aGpucmtjYnZpcG15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2OTI1NTAsImV4cCI6MjA4OTI2ODU1MH0.YLwErv7tMzbRPyL93vrhThK9zSP0wkNNvhvx3-WgMdE';

  Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  Supabase get client => Supabase.instance;
}

final supabaseService = SupabaseService();
