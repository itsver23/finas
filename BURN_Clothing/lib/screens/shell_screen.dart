import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../services/store_service.dart';
import 'screens.dart';

class Shell extends StatefulWidget {const Shell({super.key});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (connected) {
      _authSubscription = db.auth.onAuthStateChange.listen((event) {
        if (!mounted) return;
        // IndexedStack keeps its pages alive: force them to re-evaluate auth.
        setState(() {});
        if (event.event == AuthChangeEvent.signedOut) {
          store.clearFavorites();
          setState(() => tab = 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  int tab=0;String search=''; final GlobalKey<ScaffoldState> shellKey=GlobalKey<ScaffoldState>();
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_)=>Scaffold(
    key:shellKey,
    drawer:ExploreDrawer(onSelect:(category,keyword){
      Navigator.pop(context);
      store.setCategory(category);
      store.setProductSearch(keyword ?? '');
      setState(()=>tab=1);
      store.acknowledgeShop();
    }),
    drawerScrimColor:Colors.black.withValues(alpha:0.65),
    appBar:AppBar(
      backgroundColor: const Color(0xFF111111),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      title:const Column(children:[Text('BURN',style:TextStyle(fontWeight:FontWeight.w900,fontSize:27,letterSpacing:2)),Text('C L O T H I N G',style:TextStyle(fontSize:8))]),centerTitle:true,
      actions:[IconButton(onPressed:(){store.acknowledgeCartNotifications();Navigator.push(context,MaterialPageRoute(builder:(_)=>const CartPage()));},icon:Badge(isLabelVisible:store.unreadCartAdds>0,label:Text('${store.unreadCartAdds}'),child:const Icon(Icons.shopping_cart_outlined)))]),
    body:IndexedStack(index:tab,children:[HomePage(key: ValueKey(tab == 0), onShop:(){setState(()=>tab=1);store.acknowledgeShop();}),const ShopPage(),WishlistPage(key: ValueKey(connected && db.auth.currentUser != null ? db.auth.currentUser!.id : 'guest')),const ProfilePage()]),
    bottomNavigationBar:NavigationBar(
      selectedIndex:tab,
      onDestinationSelected: (i) async {
        if (i == 3 && (!connected || db.auth.currentUser == null)) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AuthPage(initialScreen: 0)),
          );
          if (!mounted) return;
          if (connected && db.auth.currentUser != null) {
            setState(() => tab = 3);
          }
          return;
        }
        setState(() => tab = i);
        if (i == 1) store.acknowledgeShop();
      },
      destinations:[
        const NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Home'),
        NavigationDestination(icon:_NavCountIcon(icon:Icons.shopping_bag_outlined,selectedIcon:Icons.shopping_bag,count:store.unreadCartAdds,selected:tab==1),label:'Shop'),
        
        NavigationDestination(icon:_NavCountIcon(icon:Icons.favorite_border,selectedIcon:Icons.favorite,count:store.favorites.length,selected:tab==2),label:'Wishlist'),
        const NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Profile'),
      ],
    ),
  ));}

// Badges count total cart quantities and unique wishlisted products.
class _NavCountIcon extends StatelessWidget {
  final IconData icon,selectedIcon;
  final int count;
  final bool selected;
  const _NavCountIcon({required this.icon,required this.selectedIcon,required this.count,required this.selected});
  @override Widget build(BuildContext context)=>TweenAnimationBuilder<double>(
    key:ValueKey('${icon.codePoint}-$count-$selected'),
    tween:Tween(begin:count>0?1.24:1.0,end:1),
    duration:const Duration(milliseconds:300),curve:Curves.easeOutBack,
    builder:(context,scale,child)=>Transform.scale(scale:scale,child:child),
    child:Badge(
      isLabelVisible:count>0,
      label:Text(count>99?'99+':'$count'),
      child:Icon(selected?selectedIcon:icon),
    ),
  );
}

