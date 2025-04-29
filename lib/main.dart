import 'package:flutter/material.dart';
import 'app.dart';
import 'core/constants/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);

  runApp(const ArtBeatApp());
}
