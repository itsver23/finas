import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// The Explore navigation is a left-side drawer, not a separate screen.
class ExploreDrawer extends StatefulWidget {
  final void Function(String category, String? keyword) onSelect;
  const ExploreDrawer({super.key, required this.onSelect});

  @override
  State<ExploreDrawer> createState() => _ExploreDrawerState();
}

class _ExploreDrawerState extends State<ExploreDrawer> {
  String section = 'Men';
  String? expanded;
  String query = '';
  final searchController = TextEditingController();

  static const menus = <String, List<String>>{
    'Men': ['VIEW ALL', 'NEW ARRIVALS', 'DENIM', 'ONE PIECE', 'TOPS', 'HOODIES', 'JACKETS', 'BOTTOMS', 'ACCESSORIES'],
    'Ladies': ['VIEW ALL', 'NEW ARRIVALS', 'DENIM', 'ONE PIECE', 'TOPS', 'DRESSES', 'JACKETS', 'BOTTOMS', 'ACCESSORIES'],
  };
  static const submenus = <String, List<String>>{
    'TOPS': ['T-Shirts', 'Polos', 'Shirts'],
    'DENIM': ['Jeans', 'Denim Jackets'],
    'ONE PIECE': ['Dresses', 'Jumpsuits'],
    'HOODIES': ['Hoodies', 'Sweatshirts'],
    'JACKETS': ['Jackets', 'Outerwear'],
    'BOTTOMS': ['Cargo Pants', 'Jeans', 'Shorts'],
    'DRESSES': ['Dresses', 'One Piece'],
    'ACCESSORIES': ['Caps', 'Bags'],
  };

  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  void select(String category, [String? keyword]) => widget.onSelect(category, keyword);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width < 600 ? width * 0.84 : 350,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 12, 12),
            child: Row(children: [
              IconButton(tooltip: 'Close Explore', icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
              Expanded(child: TextField(
                controller: searchController,
                onChanged: (value) => setState(() => query = value.trim()),
                onSubmitted: (value) => select(section, value.trim().isEmpty ? null : value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                  suffixIcon: TextButton(onPressed: () {
                    searchController.clear(); setState(() => query = '');
                  }, child: const Text('CLEAR', style: TextStyle(color: red, fontSize: 10))),
                ),
              )),
            ]),
          ),
          Row(children: [for (final name in ['Men', 'Ladies']) Expanded(
            child: InkWell(onTap: () => setState(() { section = name; expanded = null; }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: section == name ? const Color(0xFF242424) : const Color(0xFF191919),
                  border: Border(bottom: BorderSide(color: section == name ? red : const Color(0xFF444444), width: 2)),
                ),
                alignment: Alignment.center,
                child: Text(name.toUpperCase(), style: TextStyle(
                  color: section == name ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w700,
                )),
              ),
            ),
          )]),
          Expanded(child: ListView(children: [
            for (final menu in menus[section]!.where((m) => query.isEmpty ||
                m.toLowerCase().contains(query.toLowerCase()) ||
                (submenus[m]?.any((s) => s.toLowerCase().contains(query.toLowerCase())) ?? false))) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(menu, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                trailing: submenus.containsKey(menu) ? Icon(expanded == menu ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down) : null,
                onTap: () {
                  if (submenus.containsKey(menu)) {
                    setState(() => expanded = expanded == menu ? null : menu);
                  } else {
                    select(section, menu == 'VIEW ALL' ? null : menu == 'NEW ARRIVALS' ? null : menu);
                  }
                },
              ),
              if (expanded == menu)
                Container(color: const Color(0xFF222222), child: Column(children: [
                  ListTile(dense: true, contentPadding: const EdgeInsets.only(left: 38, right: 16),
                    title: Text('Shop All $menu', style: const TextStyle(color: Colors.white70)),
                    onTap: () => select(section, menu)),
                  for (final sub in submenus[menu]!)
                    ListTile(dense: true, contentPadding: const EdgeInsets.only(left: 38, right: 16),
                      title: Text(sub, style: const TextStyle(color: Colors.white70)),
                      onTap: () => select(section, sub)),
                ])),
              const Divider(height: 1, color: Color(0xFF303030)),
            ],
          ])),
          const Divider(height: 1, color: Color(0xFF303030)),
          Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Discover your next BURN look.', style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => select('All'),
                child: const Text('SHOP ALL PRODUCTS', style: TextStyle(color: red))),
            ],
          )),
        ]),
      ),
    );
  }
}
