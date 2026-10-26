import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const red = Color(0xFFE50920);
const black = Color(0xFF111111);

// Supply these values at build/run time. Never include a service-role or
// Xendit secret key in the Flutter app.
const supaUrl = String.fromEnvironment('SUPABASE_URL');
const supaKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get connected => Uri.tryParse(supaUrl)?.hasScheme == true &&
    Uri.tryParse(supaUrl)?.host.endsWith('.supabase.co') == true &&
    supaKey.isNotEmpty;

SupabaseClient get db => Supabase.instance.client;
