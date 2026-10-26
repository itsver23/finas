import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const red = Color(0xFFE50920);
const black = Color(0xFF111111);

// Public client configuration only. Never add a service-role or Xendit secret.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gdyqpcneahghhuttwjdc.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_VC1m73fLrgTucZySGIUIdA_pX-zRCVj',
  );
}

// Compatibility with existing BURN screens/services; no UI edits required.
const supaUrl = AppConfig.supabaseUrl;
const supaKey = AppConfig.supabaseAnonKey;

bool get connected => Uri.tryParse(supaUrl)?.scheme == 'https' &&
    Uri.tryParse(supaUrl)?.host.endsWith('.supabase.co') == true &&
    supaKey.isNotEmpty;

SupabaseClient get db => Supabase.instance.client;
