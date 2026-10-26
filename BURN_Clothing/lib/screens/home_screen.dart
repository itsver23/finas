import 'dart:async';
import 'package:flutter/material.dart';
import '../services/store_service.dart';

/// Four original BURN campaign artworks, one at a time.
/// Automatic slide: 10 seconds. Manual vertical swipe stops auto-sliding
/// until the user leaves Home and returns.
class HomePage extends StatefulWidget {
  final VoidCallback onShop;
  const HomePage({super.key, required this.onShop});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _interval = Duration(seconds: 10);
  static const _animation = Duration(milliseconds: 700);
  final PageController _pages = PageController();
  Timer? _timer;
  bool _manualLock = false;
  int _current = 0;

  static const _campaigns = <String>[
    'assets/campaigns/new_arrivals.jpg',
    'assets/campaigns/gifting.jpg',
    'assets/campaigns/arise.jpg',
    'assets/campaigns/men_ladies.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) => _next());
  }

  Future<void> _next() async {
    if (!mounted || _manualLock || !_pages.hasClients) return;
    await _pages.animateToPage(
      (_current + 1) % _campaigns.length,
      duration: _animation,
      curve: Curves.easeInOutCubic,
    );
  }

  void _shop(String category) {
    store.setCategory(category);
    store.setProductSearch('');
    widget.onShop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _manualLock = true;
          _timer?.cancel();
        }
        return false;
      },
      child: PageView.builder(
        controller: _pages,
        scrollDirection: Axis.vertical,
        itemCount: _campaigns.length,
        onPageChanged: (value) => _current = value,
        itemBuilder: (context, index) {
          return LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFF111111),
                  child: Image.asset(
                    _campaigns[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text('Campaign image unavailable')),
                  ),
                ),
                // Cover the baked promotional CTA from the reference artwork;
                // real Flutter buttons below provide working interactions.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: constraints.maxHeight * 0.17,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xED080808)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: index == 3
                      ? Row(
                          children: [
                            Expanded(
                              child: _CampaignButton(
                                label: 'SHOP MEN',
                                onTap: () => _shop('Men'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CampaignButton(
                                label: 'SHOP LADIES',
                                onTap: () => _shop('Ladies'),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: SizedBox(
                            width: (constraints.maxWidth * 0.62).clamp(120.0, 320.0),
                            child: _CampaignButton(
                              label: 'SHOP NOW',
                              onTap: () => _shop('All'),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Tap scale and red-glow feedback; buttons are real and route to Shop.
class _CampaignButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CampaignButton({required this.label, required this.onTap});

  @override
  State<_CampaignButton> createState() => _CampaignButtonState();
}

class _CampaignButtonState extends State<_CampaignButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFE50920) : const Color(0xE8000000),
          border: Border.all(color: _pressed ? const Color(0xFFE50920) : Colors.white, width: 1.5),
          boxShadow: _pressed
              ? [BoxShadow(color: const Color(0xFFE50920).withValues(alpha: 0.6), blurRadius: 20)]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) {
              if (mounted) setState(() => _pressed = value);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
