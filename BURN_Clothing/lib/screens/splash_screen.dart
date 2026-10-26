import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'screens.dart';

class SplashPage extends StatefulWidget {const SplashPage({super.key}); @override State<SplashPage> createState()=>_SplashState();}
class _SplashState extends State<SplashPage> {
  @override void initState(){super.initState(); Future.delayed(const Duration(milliseconds:1100),(){if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const LoadingPage()));});}
  @override Widget build(BuildContext context)=>const Scaffold(backgroundColor: black,body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text('BURN',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:64,letterSpacing:4)),Text('C L O T H I N G',style:TextStyle(color:Colors.white)),SizedBox(height:36),Text('WEAR YOUR FIRE.',style:TextStyle(color:red,letterSpacing:4))])));
}
