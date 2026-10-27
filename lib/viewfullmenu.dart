import 'package:flutter/material.dart';

import 'addtocart.dart';
import 'auth.dart';
import 'database/menu_database.dart';
import 'database/order_database.dart';
import 'find_us.dart';
import 'widgets/animated_entry.dart';
import 'widgets/soft_background.dart';
import 'widgets/user_avatar.dart';
import 'account.dart';
import 'widgets/featured_section.dart';

const _espresso = Color(0xFF34221B);
const _coffee = Color(0xFF76513B);
const _caramel = Color(0xFFC66B3D);
const _cream = Color(0xFFFAF7F2);
const _muted = Color(0xFF81766F);
const _cardBorder = Color(0xFFEDE6DF);
const _cardRadius = 18.0;

class FullMenuPage extends StatefulWidget {
  const FullMenuPage({super.key});

  @override
  State<FullMenuPage> createState() => _FullMenuPageState();
}

class _FullMenuPageState extends State<FullMenuPage> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _deliveryAddress = '';
  final Map<String, CartEntry> _cart = {};
  final Set<String> _favorites = {};
  bool _bestSellersOnly = false;
  bool _favoritesOnly = false;
  String _priceSort = 'Featured';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CafeMenuItem> get _activeMenu {
    final menu =
        (_selectedTab == 0 ? MenuDatabase.coffeeMenu : MenuDatabase.pizzaMenu)
            .where((item) => !_bestSellersOnly || item.isBestSeller)
            .where(
              (item) =>
                  !_favoritesOnly ||
                  _favorites.contains(item.name.toLowerCase()),
            )
            .toList();
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? menu
        : menu.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query);
          }).toList();
    if (_priceSort == 'Price: low to high') {
      filtered.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
    } else if (_priceSort == 'Price: high to low') {
      filtered.sort((a, b) => _priceOf(b).compareTo(_priceOf(a)));
    }
    return filtered;
  }

  List<CartEntry> get _cartItems => List.unmodifiable(_cart.values);

  int get _cartItemCount =>
      _cartItems.fold<int>(0, (sum, entry) => sum + entry.quantity);

  double _priceOf(CafeMenuItem item) {
    final price = double.tryParse(
      item.price.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (price == null) {
      throw FormatException('Invalid price for ${item.name}: ${item.price}');
    }
    return price;
  }

  double get _cartSubtotal => _cartItems.fold<double>(
    0,
    (sum, entry) => sum + entry.unitPrice * entry.quantity,
  );

  Future<void> _showAddToCart(CafeMenuItem item) async {
    final entry = await showDialog<CartEntry>(
      context: context,
      builder: (_) => AddToCartDialog(
        item: item,
        price: _priceOf(item),
        isPizza: _selectedTab == 1,
      ),
    );
    if (entry == null || !mounted) return;

    setState(() {
      final existing = _cart[entry.key];
      _cart[entry.key] = entry.copyWith(
        quantity: entry.quantity + (existing?.quantity ?? 0),
      );
    });
  }

  Future<void> _checkoutCart() async {
    final entries = _cartItems;
    if (entries.isEmpty) return;

    final checkout = await showDialog<CartCheckoutResult>(
      context: context,
      builder: (_) => CartCheckoutDialog(
        entries: entries,
        initialAddress: _deliveryAddress,
      ),
    );
    if (checkout == null || !mounted) return;

    final orderLines = entries
        .where((entry) => (checkout.quantities[entry.key] ?? 0) > 0)
        .map(
          (entry) => OrderLine(
            name: entry.item.name,
            quantity: checkout.quantities[entry.key]!,
            unitPrice: entry.unitPrice,
            customizations: entry.options,
          ),
        )
        .toList();
    if (orderLines.isEmpty) return;

    final address = checkout.address;
    OrderDatabase.instance.addOrder(
      customerName: AppSession.instance.username ?? 'Customer',
      deliveryAddress: address,
      items: orderLines,
      total:
          orderLines.fold<double>(0, (sum, line) => sum + line.total) +
          CartCheckoutDialog.deliveryFee,
    );
    _deliveryAddress = address;
    setState(_cart.clear);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Your order has been placed.'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SoftBackground(child: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final horizontalPadding = viewport.maxWidth < 380 ? 16.0 : 20.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        _cart.isEmpty ? 24 : 124,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildGreeting(),
                          const SizedBox(height: 16),
                          const PromoBanners(),
                          const SizedBox(height: 20),
                          FeaturedRow(
                            items: [
                              ...MenuDatabase.coffeeMenu,
                              ...MenuDatabase.pizzaMenu,
                            ].where((i) => i.isBestSeller && i.isAvailable).toList(),
                            onOrder: _showAddToCart,
                          ),
                          const SizedBox(height: 20),
                          _buildHero(),
                          const SizedBox(height: 20),
                          _buildSearch(),
                          const SizedBox(height: 16),
                          const Text(
                            'CLICK THE MENU',
                            style: TextStyle(
                              color: _espresso,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCategories(),
                          const SizedBox(height: 18),
                          _MenuSectionHeader(
                            title: _selectedTab == 0
                                ? 'Coffee & more'
                                : 'Straight from the oven',
                            subtitle: _selectedTab == 0
                                ? 'Made fresh, just for you'
                                : 'Your pizza night starts here',
                            itemCount: _activeMenu.length,
                          ),
                          const SizedBox(height: 14),
                          _buildMenuFilters(),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0, 0.025),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: _activeMenu.isEmpty
                                ? Container(
                                    key: ValueKey<String>(_searchQuery),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 30,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          color: _muted,
                                          size: 32,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'No menu items found. Try another search.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: _muted),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    key: ValueKey<int>(_selectedTab),
                                    children: _activeMenu
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: FadeSlideIn(delay: Duration(milliseconds: 40 * _activeMenu.indexOf(item).clamp(0, 10).toInt()), child: _MenuProductCard(
                                              item: item,
                                              category: _selectedTab == 0
                                                  ? 'COFFEE'
                                                  : 'PIZZA',
                                              isFavorite: _favorites.contains(
                                                item.name.toLowerCase(),
                                              ),
                                              onFavorite: () {
                                                setState(() {
                                                  final key = item.name
                                                      .toLowerCase();
                                                  if (!_favorites.add(key)) {
                                                    _favorites.remove(key);
                                                  }
                                                });
                                              },
                                              onOrder: () =>
                                                  _showAddToCart(item),
                                            )),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_cart.isNotEmpty)
            Positioned(left: 0, right: 0, bottom: 0, child: _buildCartBar()),
        ],
      )),
    );
  }

  Widget _buildMenuFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          avatar: const Icon(Icons.local_fire_department_outlined, size: 16),
          label: const Text('Best sellers'),
          selected: _bestSellersOnly,
          onSelected: (selected) => setState(() => _bestSellersOnly = selected),
          selectedColor: const Color(0xFFF1E5D9),
          labelStyle: const TextStyle(fontSize: 12, color: _espresso),
          visualDensity: VisualDensity.compact,
          side: const BorderSide(color: _cardBorder),
        ),
        FilterChip(
          avatar: const Icon(Icons.favorite_border_rounded, size: 16),
          label: const Text('Favorites'),
          selected: _favoritesOnly,
          onSelected: (selected) => setState(() => _favoritesOnly = selected),
          selectedColor: const Color(0xFFF1E5D9),
          labelStyle: const TextStyle(fontSize: 12, color: _espresso),
          visualDensity: VisualDensity.compact,
          side: const BorderSide(color: _cardBorder),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _cardBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _priceSort,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(
                color: _espresso,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Featured',
                  child: Text('Featured order'),
                ),
                DropdownMenuItem(
                  value: 'Price: low to high',
                  child: Text('Price: low to high'),
                ),
                DropdownMenuItem(
                  value: 'Price: high to low',
                  child: Text('Price: high to low'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priceSort = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartBar() {
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 16,
                  12,
                  compact ? 8 : 12,
                  12,
                ),
                decoration: BoxDecoration(
                  color: _espresso,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _espresso.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 36 : 42,
                      height: compact ? 36 : 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Badge(
                          label: Text('$_cartItemCount'),
                          backgroundColor: _caramel,
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_cartItemCount ${_cartItemCount == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₱${_cartSubtotal.toStringAsFixed(2)} subtotal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: compact ? 10 : 12,
                            ),
                          ),
                          Text(
                            '₱${(_cartSubtotal + CartCheckoutDialog.deliveryFee).toStringAsFixed(2)} total with delivery',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: compact ? 9 : 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: _checkoutCart,
                      style: FilledButton.styleFrom(
                        backgroundColor: _caramel,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'Checkout',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openAccount() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => AccountPage(
              onOpenOrders: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _CustomerOrdersPage(),
                  ),
                );
              },
              onOpenFindUs: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FindUsPage()),
                );
              },
            ),
          ),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  Widget _buildGreeting() {
    final username = AppSession.instance.username;
    if (username == null || username.isEmpty) return const SizedBox.shrink();
    final name = AccountStore.instance.displayNameOf(username);
    return GestureDetector(
      onTap: _openAccount,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF533324).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(username: username, size: 60, editable: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _espresso,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'What are you craving today?',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap your photo to change it',
                  style: TextStyle(color: _caramel, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E4D8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.local_cafe_rounded, color: _coffee, size: 25),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cafepizza',
                style: TextStyle(
                  color: _espresso,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Coffee, pizza & good company',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Find us',
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const FindUsPage()));
          },
          icon: const Icon(Icons.location_on_outlined, color: _coffee),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: const Size(44, 44),
          ),
        ),
        const SizedBox(width: 4),
        if (AppSession.instance.role == AppRole.customer) ...[
          IconButton(
            tooltip: 'My orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _CustomerOrdersPage(),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded, color: _coffee),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(44, 44),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'My account',
            onPressed: _openAccount,
            icon: const Icon(Icons.person_rounded, color: _coffee),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        return Container(
          height: isCompact ? 204 : 230,
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isCompact ? 17 : 22,
            isCompact ? 10 : 16,
            10,
            isCompact ? 10 : 16,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF533324), Color(0xFF9B5735), Color(0xFFD18A4D)],
              begin: Alignment.centerLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                flex: isCompact ? 7 : 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Text(
                        'FRESHLY MADE, ALWAYS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 8 : 11),
                    Text(
                      'A little comfort,\na lot of flavor.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 21 : 26,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: isCompact ? 6 : 8),
                    Text(
                      'Your coffee-and-pizza kind of place.',
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: isCompact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: isCompact ? 3 : 5,
                child: Image.asset(
                  'lib/images/bgpizza.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Freshly baked Margherita pizza',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search coffee or pizza',
        hintStyle: const TextStyle(color: _muted, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: _coffee),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, color: _muted),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: const BorderSide(color: Color(0xFFEDE6DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: const BorderSide(color: _caramel, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Row(
      children: [
        Expanded(
          child: _CategoryCard(
            label: 'CAFE',
            title: 'Coffee',
            image: 'lib/images/matcha123.jpg',
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CategoryCard(
            label: 'PIZZA',
            title: 'Pizza',
            image: 'lib/images/piza2.jpg',
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.title,
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String title;
  final String image;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title menu',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_cardRadius),
          splashColor: _caramel.withValues(alpha: 0.08),
          highlightColor: _caramel.withValues(alpha: 0.04),
          child: AnimatedContainer(
            height: 58,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF7F0) : Colors.white,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(
                color: isSelected ? _caramel : _cardBorder,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _caramel.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedScale(
                    scale: isSelected ? 1 : 0.94,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Image.asset(
                      image,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _espresso,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 16,
                  height: 18,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected ? _caramel : const Color(0xFFB9AAA0),
                      size: isSelected ? 13 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuSectionHeader extends StatelessWidget {
  const _MenuSectionHeader({
    required this.title,
    required this.subtitle,
    required this.itemCount,
  });

  final String title;
  final String subtitle;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _espresso,
                  fontSize: 23,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1E9E1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
            style: const TextStyle(
              color: _coffee,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerOrdersPage extends StatelessWidget {
  const _CustomerOrdersPage();

  @override
  Widget build(BuildContext context) {
    final username = AppSession.instance.username;
    final normalizedUsername = username?.trim().toLowerCase();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _espresso,
        title: const Text(
          'My orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<List<CustomerOrder>>(
          valueListenable: OrderDatabase.instance.orders,
          builder: (context, allOrders, _) {
            final orders = allOrders.where((order) {
              return normalizedUsername != null &&
                  order.customerName.trim().toLowerCase() == normalizedUsername;
            }).toList();

            if (orders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: _muted,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No orders yet',
                        style: TextStyle(
                          color: _espresso,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Your orders will appear here, ${username ?? 'customer'}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _CustomerOrderCard(order: orders[index]),
            );
          },
        ),
      ),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final trackingStatus = switch (order.status) {
      'Pending' || 'Order Received' => 'Order Received',
      'Preparing' => 'Preparing',
      'On the way' || 'Ready for Pickup' => 'Ready for Pickup',
      'Delivered' || 'Completed' => 'Completed',
      'Cancelled' => 'Cancelled',
      _ => order.status,
    };
    final statusColor = switch (trackingStatus) {
      'Pending' => const Color(0xFFC27822),
      'Order Received' => const Color(0xFFC27822),
      'Preparing' => const Color(0xFF6652A3),
      'Ready for Pickup' => const Color(0xFF3676A8),
      'Completed' => const Color(0xFF40845A),
      'Cancelled' => const Color(0xFFB44E48),
      _ => _muted,
    };
    final date = order.createdAt;
    final dateLabel =
        '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  style: const TextStyle(
                    color: _espresso,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trackingStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateLabel, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity} × ${item.name}',
                    style: const TextStyle(
                      color: _espresso,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.customizations.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.customizations.join(' · '),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (trackingStatus != 'Cancelled') ...[
            const SizedBox(height: 12),
            _OrderProgress(status: trackingStatus),
          ],
          if (trackingStatus == 'Cancelled')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'This order was cancelled.',
                style: TextStyle(
                  color: Color(0xFFB44E48),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Divider(height: 18, color: _cardBorder),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: _muted, size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _espresso,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (order.deliveryProofBytes != null) ...[
            const SizedBox(height: 14),
            const Text(
              'Delivery photo',
              style: TextStyle(
                color: _espresso,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                order.deliveryProofBytes!,
                width: 180,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Order Received',
      'Preparing',
      'Ready for Pickup',
      'Completed',
    ];
    final activeIndex = steps.indexOf(status).clamp(0, steps.length - 1);
    return Row(
      children: List.generate(steps.length, (index) {
        final complete = index <= activeIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index <= activeIndex
                            ? _caramel
                            : const Color(0xFFEDE6DF),
                      ),
                    ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: complete ? _caramel : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: complete ? _caramel : _cardBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < activeIndex
                            ? _caramel
                            : const Color(0xFFEDE6DF),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: complete ? _coffee : _muted,
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: index == activeIndex
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MenuProductCard extends StatelessWidget {
  const _MenuProductCard({
    required this.item,
    required this.category,
    required this.isFavorite,
    required this.onFavorite,
    required this.onOrder,
  });

  final CafeMenuItem item;
  final String category;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final isCoffee = category == 'COFFEE';
    final accent = isCoffee ? _coffee : _caramel;
    final tint = isCoffee ? const Color(0xFFF2E9DF) : const Color(0xFFFFEEE5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final imageSize = compact ? 72.0 : 84.0;
        return HoverLift(child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF533324).withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  color: tint,
                  child: Image.asset(item.image, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.isBestSeller || !item.isAvailable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          item.isAvailable ? '🔥 BEST SELLER' : 'SOLD OUT',
                          style: TextStyle(
                            color: item.isAvailable
                                ? _caramel
                                : Color(0xFFB44E48),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _espresso,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            tooltip: isFavorite
                                ? 'Remove ${item.name} from favorites'
                                : 'Add ${item.name} to favorites',
                            onPressed: onFavorite,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite ? _caramel : _muted,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.rating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Color(0xFFC27822),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.price,
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Order ${item.name}',
                button: true,
                child: FilledButton(
                  onPressed: item.isAvailable ? onOrder : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(compact ? 54 : 74, 38),
                    padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    item.isAvailable ? 'Order' : 'Sold out',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ));
      },
    );
  }
}
