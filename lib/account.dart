import 'package:flutter/material.dart';

import 'auth.dart';
import 'database/order_database.dart';
import 'widgets/soft_background.dart';
import 'widgets/user_avatar.dart';

const _espresso = Color(0xFF34221B);
const _coffee = Color(0xFF76513B);
const _caramel = Color(0xFFC66B3D);
const _muted = Color(0xFF81766F);
const _cardBorder = Color(0xFFEDE6DF);

/// Keeps the customer's profile details in memory while the app is running.
class AccountStore extends ChangeNotifier {
  AccountStore._();

  static final instance = AccountStore._();

  final Map<String, String> _names = {};
  final Map<String, String> _phones = {};
  final Map<String, String> _addresses = {};

  String displayNameOf(String username) {
    final saved = _names[username];
    if (saved != null && saved.trim().isNotEmpty) return saved;
    if (username.isEmpty) return 'Guest';
    return username[0].toUpperCase() + username.substring(1);
  }

  String phoneOf(String username) => _phones[username] ?? '';

  String addressOf(String username) => _addresses[username] ?? '';

  void save(String username, {String? name, String? phone, String? address}) {
    if (name != null) _names[username] = name.trim();
    if (phone != null) _phones[username] = phone.trim();
    if (address != null) _addresses[username] = address.trim();
    notifyListeners();
  }
}

/// The "Account" screen of the customer, similar to the profile tab of
/// popular food-delivery apps.
class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.onOpenOrders,
    required this.onOpenFindUs,
  });

  final VoidCallback onOpenOrders;
  final VoidCallback onOpenFindUs;

  void _signOut(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppSession.instance.signOut();
  }

  void _showSheet(
    BuildContext context, {
    required String title,
    required List<String> labels,
    required List<String> initial,
    required List<TextInputType> keyboards,
    required void Function(List<String> values) onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => _FieldsSheet(
        title: title,
        labels: labels,
        initial: initial,
        keyboards: keyboards,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = AppSession.instance.username ?? '';
    final normalized = username.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SoftBackground(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            AccountStore.instance,
            OrderDatabase.instance.orders,
          ]),
          builder: (context, _) {
            final store = AccountStore.instance;
            final myOrders = OrderDatabase.instance.orders.value.where((order) {
              return order.customerName.trim().toLowerCase() == normalized;
            }).toList();
            final delivered = myOrders
                .where((order) => order.status == 'Delivered')
                .length;
            final spent = myOrders.fold<double>(
              0,
              (sum, order) => sum + order.total,
            );
            final phone = store.phoneOf(username);
            final address = store.addressOf(username);

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context, store, username),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildStats(myOrders.length, delivered, spent),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('My account'),
                        _AccountTile(
                          icon: Icons.person_outline_rounded,
                          title: 'My profile',
                          subtitle: phone.isEmpty
                              ? 'Add your name and phone number'
                              : phone,
                          onTap: () => _showSheet(
                            context,
                            title: 'My profile',
                            labels: const ['Full name', 'Phone number'],
                            initial: [store.displayNameOf(username), phone],
                            keyboards: const [
                              TextInputType.name,
                              TextInputType.phone,
                            ],
                            onSave: (values) => store.save(
                              username,
                              name: values[0],
                              phone: values[1],
                            ),
                          ),
                        ),
                        _AccountTile(
                          icon: Icons.location_on_outlined,
                          title: 'Delivery address',
                          subtitle: address.isEmpty
                              ? 'No address saved yet'
                              : address,
                          onTap: () => _showSheet(
                            context,
                            title: 'Delivery address',
                            labels: const ['Street, barangay, city'],
                            initial: [address],
                            keyboards: const [TextInputType.streetAddress],
                            onSave: (values) =>
                                store.save(username, address: values[0]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _SectionLabel('Activity'),
                        _AccountTile(
                          icon: Icons.receipt_long_rounded,
                          title: 'My orders',
                          subtitle: myOrders.isEmpty
                              ? 'You have no orders yet'
                              : '${myOrders.length} '
                                    '${myOrders.length == 1 ? 'order' : 'orders'}',
                          onTap: onOpenOrders,
                        ),
                        _AccountTile(
                          icon: Icons.storefront_outlined,
                          title: 'Find us',
                          subtitle: 'Store location and opening hours',
                          onTap: onOpenFindUs,
                        ),
                        const SizedBox(height: 10),
                        const _SectionLabel('More'),
                        _AccountTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About Cafepizza',
                          subtitle: 'Coffee, pizza & good company',
                          onTap: () => showAboutDialog(
                            context: context,
                            applicationName: 'Cafepizza',
                            applicationVersion: '1.0',
                            children: const [
                              Text(
                                'A coffee and pizza ordering app. Browse the '
                                'menu, customize your order, and track your '
                                'delivery.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _signOut(context),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB3412C),
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: Color(0xFFE8C9C0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccountStore store,
    String username,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.of(context).padding.top + 8,
        12,
        56,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B3A2A), Color(0xFFC66B3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'My account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          UserAvatar(username: username, size: 96, editable: true),
          const SizedBox(height: 12),
          Text(
            store.displayNameOf(username),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '@$username',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Cafepizza Member',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int orders, int delivered, double spent) {
    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _espresso,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF533324).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          stat('$orders', 'Orders'),
          stat('$delivered', 'Delivered'),
          stat('₱${spent.toStringAsFixed(0)}', 'Total spent'),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E7DA),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: _caramel, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _espresso,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _coffee),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldsSheet extends StatefulWidget {
  const _FieldsSheet({
    required this.title,
    required this.labels,
    required this.initial,
    required this.keyboards,
    required this.onSave,
  });

  final String title;
  final List<String> labels;
  final List<String> initial;
  final List<TextInputType> keyboards;
  final void Function(List<String> values) onSave;

  @override
  State<_FieldsSheet> createState() => _FieldsSheetState();
}

class _FieldsSheetState extends State<_FieldsSheet> {
  late final List<TextEditingController> _controllers = [
    for (final value in widget.initial) TextEditingController(text: value),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: _espresso,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _controllers.length; i++) ...[
            TextField(
              controller: _controllers[i],
              keyboardType: widget.keyboards[i],
              decoration: InputDecoration(
                labelText: widget.labels[i],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSave([
                  for (final controller in _controllers) controller.text,
                ]);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _caramel,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
