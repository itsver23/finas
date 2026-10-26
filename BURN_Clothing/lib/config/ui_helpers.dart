import 'package:flutter/material.dart';
String peso(num amount) => '₱${amount.toStringAsFixed(0)}';
void notice(BuildContext c,String msg) { if(c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg))); }
