import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/store_service.dart';
import 'product_screen.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: store.productSearch);
    store.addListener(_syncSearch);
  }

  void _syncSearch() {
    if (_searchController.text != store.productSearch) {
      _searchController.value = TextEditingValue(
        text: store.productSearch,
        selection: TextSelection.collapsed(offset: store.productSearch.length),
      );
    }
  }

  @override
  void dispose() {
    store.removeListener(_syncSearch);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final query = store.productSearch.trim().toLowerCase();
        final products = store.items.where((p) {
          final categoryMatches =
              store.category == 'All' || p.category == store.category;
          final searchMatches =
              query.isEmpty || p.name.toLowerCase().contains(query);
          return categoryMatches && searchMatches;
        }).toList();

        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Shop',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: TextField(
                controller: _searchController,
                onChanged: store.setProductSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search BURN products...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: store.productSearch.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => store.setProductSearch(''),
                        ),
                  filled: true,
                  fillColor: const Color(0xFF222222),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF484848)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF484848)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: red, width: 1.5),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final c in [
                    'All',
                    'Men',
                    'Ladies',
                    'Unisex',
                    'Accessories',
                    'Footwear'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: store.category == c,
                        selectedColor: red,
                        backgroundColor: const Color(0xFF222222),
                        side: BorderSide.none,
                        onSelected: (_) => store.setCategory(c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (store.loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text(store.loadError!, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.orangeAccent)),
                    TextButton.icon(
                      onPressed: store.loadingProducts ? null : () { store.load(); },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading products'),
                    ),
                  ],
                ),
              ),
            if (store.loadingProducts)
              const Center(child: CircularProgressIndicator()),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: Text('No products found')),
              )
            else
              ProductGrid(products: products),
          ],
        );
      },
    );
  }
}
