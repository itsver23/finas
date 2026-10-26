import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/item.dart';
class Store extends ChangeNotifier {
  List<Item> items = List.of(demoItems);
  String? loadError;
  bool loadingProducts = false;
  final Map<String,int> quantities = {};
  final Set<String> favorites = {};
  String category='All';
  String productSearch='';
  void setProductSearch(String value) {productSearch=value;notifyListeners();}
  // New cart additions not yet acknowledged by opening the Shop tab.
  int unreadCartAdds = 0;
  void acknowledgeShop() {
    if (unreadCartAdds == 0) return;
    unreadCartAdds = 0;
    notifyListeners();
  }
  void acknowledgeCartNotifications() => acknowledgeShop();
  void clearFavorites() { if (favorites.isNotEmpty) { favorites.clear(); notifyListeners(); } }
  bool get isDemo => !connected || items.any((p)=>p.id.startsWith('demo-'));
  int get count => quantities.values.fold(0,(a,b)=>a+b);
  int get subtotal => quantities.entries.fold(0,(a,e)=>a+(items.where((p)=>p.id==e.key).firstOrNull?.price??0)*e.value);
  List<Item> get cart => items.where((p)=>(quantities[p.id]??0)>0).toList();
  Future<void> load() async {
    if (!connected) {
      loadError = 'Supabase is not configured. Check SUPABASE_URL and SUPABASE_ANON_KEY.';
      notifyListeners();
      return;
    }
    loadingProducts = true;
    loadError = null;
    notifyListeners();
    try {
      final rows = await db.from('products').select().eq('active', true).order('created_at');
      final loaded = (rows as List)
          .map((row) => Item.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      items = loaded;
      if (loaded.isEmpty) {
        loadError = 'No active products returned by Supabase. Check the products table and read policies.';
      }
    } catch (error) {
      // Preserve the last successful catalog instead of silently erasing it.
      loadError = 'Could not load products: $error';
      debugPrint(loadError);
    } finally {
      loadingProducts = false;
      notifyListeners();
    }
  }
  void setCategory(String value) { category = value; notifyListeners(); }
  void add(Item p) {if((quantities[p.id]??0)>=p.stock)return; quantities[p.id]=(quantities[p.id]??0)+1;unreadCartAdds++;notifyListeners();}
  void change(Item p,int delta) { final n=(quantities[p.id]??0)+delta; if(n<0||n>p.stock)return; if(n==0){quantities.remove(p.id);}else{quantities[p.id]=n;}notifyListeners(); }
  void toggle(Item p) {favorites.contains(p.id)?favorites.remove(p.id):favorites.add(p.id);notifyListeners();}
  void clear(){quantities.clear();unreadCartAdds=0;notifyListeners();}
}
final store=Store();
