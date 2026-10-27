import 'package:flutter/material.dart';

import '../database/menu_database.dart';

const _espresso = Color(0xFF34221B);
const _caramel = Color(0xFFC66B3D);
const _muted = Color(0xFF81766F);
const _cardBorder = Color(0xFFEDE6DF);

/// Swipeable promo banners shown at the top of the menu.
class PromoBanners extends StatefulWidget {
  const PromoBanners({super.key});

  @override
  State<PromoBanners> createState() => _PromoBannersState();
}

class _PromoBannersState extends State<PromoBanners> {
  static const _banners = [
    ('Fresh from the oven', 'Try our best-selling pizzas today',
        Icons.local_pizza_rounded, Color(0xFFB5502A), Color(0xFFE08A4B)),
    ('Cold brew season', 'Iced coffees made just the way you like',
        Icons.local_cafe_rounded, Color(0xFF4A2F22), Color(0xFF9B6240)),
    ('Made fresh, sent fast', 'Order now and track your rider live',
        Icons.delivery_dining_rounded, Color(0xFF23866A), Color(0xFF5CB89A)),
  ];

  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 128,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final (title, subtitle, icon, start, end) = _banners[index];
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: [start, end]),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.85)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? _caramel : const Color(0xFFD9CCC0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Horizontal "Featured" list of best-selling items.
class FeaturedRow extends StatelessWidget {
  const FeaturedRow({super.key, required this.items, required this.onOrder});

  final List<CafeMenuItem> items;
  final void Function(CafeMenuItem item) onOrder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_fire_department_rounded, color: _caramel, size: 22),
            SizedBox(width: 6),
            Text(
              'Featured',
              style: TextStyle(
                color: _espresso,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Our customers\' favorites',
            style: TextStyle(color: _muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => onOrder(item),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(item.image, fit: BoxFit.cover),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _caramel,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Best seller',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _espresso,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.price,
                              style: const TextStyle(
                                color: _caramel,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.add_circle_rounded,
                            color: _caramel,
                            size: 26,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
