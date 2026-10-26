import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart' as auth_config;
import '../config/app_config.dart';
import '../config/ui_helpers.dart';
import '../services/store_service.dart';
import 'screens.dart';
class WishlistPage extends StatefulWidget {
 const WishlistPage({super.key});
 @override State<WishlistPage> createState() => _WishlistPageState();
}
class _WishlistPageState extends State<WishlistPage> {
 StreamSubscription<AuthState>? _authSubscription;
 @override void initState() {
   super.initState();
   if (auth_config.connected) {
     _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
       if (mounted) setState(() {});
     });
   }
 }
 @override void dispose() {
   _authSubscription?.cancel();
   super.dispose();
 }
 @override Widget build(BuildContext context) {
 if (!auth_config.connected || Supabase.instance.client.auth.currentUser == null) {
   return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(
     mainAxisSize:MainAxisSize.min,children:[
       const Icon(Icons.favorite_border,size:55,color:Colors.white54),
       const SizedBox(height:14),
       const Text('Log in to use your wishlist',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
       const SizedBox(height:12),
       FilledButton(onPressed:() async { await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AuthPage(initialScreen: 0))); if (mounted) setState(() {}); },child:const Text('LOG IN')),
     ],)));
 }
 return AnimatedBuilder(animation:store,builder:(context,_){final saved=store.items.where((p)=>store.favorites.contains(p.id)).toList();return saved.isEmpty?const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.favorite_border,size:52,color:Colors.white38),SizedBox(height:12),Text('Your wishlist is empty'),Text('Save pieces you love',style:TextStyle(color:Colors.white54))])):ListView(padding:const EdgeInsets.all(14),children:[Text('Wishlist (${saved.length})',style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:12),for(final p in saved)Card(child:ListTile(contentPadding:const EdgeInsets.all(8),leading:SizedBox(width:58,height:65,child:ProductImage(item:p,fit:BoxFit.contain)),title:Text(p.name),subtitle:Text(peso(p.price),style:const TextStyle(color:red,fontWeight:FontWeight.bold)),trailing:IconButton(onPressed:(){if(auth_config.connected && Supabase.instance.client.auth.currentUser != null)store.toggle(p);},icon:const Icon(Icons.favorite,color:red)),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductPage(item:p)))))]);} );}
}
