import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'auth.dart';
import 'database/order_database.dart';
import 'widgets/animated_entry.dart';
import 'widgets/soft_background.dart';
import 'widgets/user_avatar.dart';
import 'widgets/rider_extras.dart';
import 'addtocart.dart' show CartCheckoutDialog;
import 'package:url_launcher/url_launcher.dart';

const _riderAccent = Color(0xFF1F7A61);
const _riderInk = Color(0xFF18332D);
const _riderMuted = Color(0xFF71827D);
const _riderBackground = Color(0xFFF3F7F5);

class RiderSignInPage extends StatefulWidget {
  const RiderSignInPage({super.key});

  @override
  State<RiderSignInPage> createState() => _RiderSignInPageState();
}

class _RiderSignInPageState extends State<RiderSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _vehicleType = 'Motorcycle';
  bool _obscurePassword = true;
  bool _isSigningUp = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = _isSigningUp
        ? AppSession.instance.registerRider(
            _usernameController.text,
            _passwordController.text,
            profile: RiderProfile(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              vehicleType: _vehicleType,
            ),
          )
        : AppSession.instance.signInRider(
            _usernameController.text,
            _passwordController.text,
          );
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _errorMessage = _isSigningUp
          ? 'That username is already in use.'
          : 'Incorrect rider username or password.';
    });
  }

  void _toggleSignUp() {
    setState(() {
      _isSigningUp = !_isSigningUp;
      _errorMessage = null;
      _formKey.currentState?.reset();
      _fullNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _vehicleType = 'Motorcycle';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _riderBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.82),
            foregroundColor: _riderInk,
            side: const BorderSide(color: Color(0xFFDDE9E4)),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAF8), Color(0xFFEAF3EF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 28,
              right: -52,
              child: _RiderBackgroundOrb(size: 180),
            ),
            Positioned(
              bottom: 12,
              left: -76,
              child: _RiderBackgroundOrb(size: 220),
            ),
            SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 680;
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        22,
                        compact ? 8 : 12,
                        22,
                        compact ? 18 : 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Card(
                          color: Colors.white,
                          elevation: 0,
                          shadowColor: _riderInk.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Color(0xFFE7EFEB)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(compact ? 22 : 28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: compact ? 66 : 76,
                                      height: compact ? 66 : 76,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2F2EC),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: const Icon(
                                        Icons.delivery_dining_rounded,
                                        size: 38,
                                        color: _riderAccent,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 16 : 20),
                                  Text(
                                    'Rider ${_isSigningUp ? 'sign up' : 'sign in'}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _riderInk,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isSigningUp
                                        ? 'Create an account to start delivering.'
                                        : 'Sign in to manage your deliveries.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _riderMuted,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 20 : 28),
                                  if (_isSigningUp) ...[
                                    TextFormField(
                                      controller: _fullNameController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.name],
                                      decoration: _riderInputDecoration(
                                        label: 'Full name',
                                        icon: Icons.badge_outlined,
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Enter your full name'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      decoration: _riderInputDecoration(
                                        label: 'Email address',
                                        icon: Icons.email_outlined,
                                      ),
                                      validator: (value) {
                                        final email = value?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'Enter your email address';
                                        }
                                        if (!RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        ).hasMatch(email)) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.telephoneNumber,
                                      ],
                                      decoration: _riderInputDecoration(
                                        label: 'Contact number',
                                        icon: Icons.phone_outlined,
                                      ),
                                      validator: (value) {
                                        final digits = (value ?? '').replaceAll(
                                          RegExp(r'\D'),
                                          '',
                                        );
                                        if (digits.length < 10 ||
                                            digits.length > 13) {
                                          return 'Enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      initialValue: _vehicleType,
                                      decoration: _riderInputDecoration(
                                        label: 'Vehicle type',
                                        icon: Icons.two_wheeler_rounded,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Motorcycle',
                                          child: Text('Motorcycle'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Bicycle',
                                          child: Text('Bicycle'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Car',
                                          child: Text('Car'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _vehicleType = value);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _RiderRequirementsCard(
                                      vehicleType: _vehicleType,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  TextFormField(
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    decoration: _riderInputDecoration(
                                      label: 'Rider username',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Enter your rider username'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: _isSigningUp
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        _isSigningUp ? null : _submit(),
                                    decoration:
                                        _riderInputDecoration(
                                          label: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            tooltip: _obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter your password';
                                      }
                                      if (_isSigningUp && value.length < 8) {
                                        return 'Use at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_isSigningUp) ...[
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: _riderInputDecoration(
                                        label: 'Confirm password',
                                        icon: Icons.lock_outline_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFB3261E),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 22),
                                  FilledButton.icon(
                                    onPressed: _submit,
                                    icon: Icon(
                                      _isSigningUp
                                          ? Icons.person_add_alt_1_rounded
                                          : Icons.login_rounded,
                                    ),
                                    label: Text(
                                      _isSigningUp
                                          ? 'Create rider account'
                                          : 'Continue to dashboard',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _riderAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(54),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _toggleSignUp,
                                    child: Text(
                                      _isSigningUp
                                          ? 'Already a rider? Sign in'
                                          : 'New rider? Create an account',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiderDashboardPage extends StatefulWidget {
  const RiderDashboardPage({super.key});

  @override
  State<RiderDashboardPage> createState() => _RiderDashboardPageState();
}

class _RiderDashboardPageState extends State<RiderDashboardPage> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    if (AppSession.instance.role != AppRole.rider) {
      return Scaffold(
        backgroundColor: _riderBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: _riderAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Rider access required',
                style: TextStyle(
                  color: _riderInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: AppSession.instance.signOut,
                style: FilledButton.styleFrom(backgroundColor: _riderAccent),
                child: const Text('Return to sign in'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _riderBackground,
      appBar: AppBar(
        backgroundColor: _riderBackground,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.delivery_dining_rounded, color: _riderAccent),
            SizedBox(width: 9),
            Text(
              'Rider hub',
              style: TextStyle(color: _riderInk, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: AppSession.instance.signOut,
            icon: const Icon(Icons.logout_rounded, color: _riderInk),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SoftBackground(
        top: const Color(0xFFE8F5EF),
        middle: const Color(0xFFF4FAF7),
        bottom: const Color(0xFFDDEFE7),
        orb: const Color(0xFF23866A),
        child: ValueListenableBuilder<List<CustomerOrder>>(
        valueListenable: OrderDatabase.instance.orders,
        builder: (context, orders, _) {
          final riderUsername = AppSession.instance.username!;
          final availableOrders = orders
              .where(
                (order) =>
                    order.acceptedByRider == null &&
                    _isReadyForRider(order.status),
              )
              .toList();
          final activeOrders = orders
              .where(
                (order) =>
                    order.acceptedByRider == riderUsername &&
                    _isActiveDelivery(order.status),
              )
              .toList();
          final completedCount = orders
              .where(
                (order) =>
                    order.acceptedByRider == riderUsername &&
                    order.status == 'Delivered',
              )
              .length;
          final recentDeliveries = orders
              .where(
                (order) =>
                    order.acceptedByRider == riderUsername &&
                    order.status == 'Delivered',
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                children: [
                  FadeSlideIn(child: _RiderWelcomeCard(
                    riderName: AppSession.instance.username ?? 'Rider',
                    isOnline: _isOnline,
                    onStatusChanged: (value) {
                      setState(() => _isOnline = value);
                    },
                  )),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _RiderStatCard(
                          icon: Icons.route_rounded,
                          label: 'Active deliveries',
                          value: '${activeOrders.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RiderStatCard(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Completed',
                          value: '$completedCount',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    child: RiderEarningsCard(
                      completed: completedCount,
                      active: activeOrders.length,
                      feePerDelivery: CartCheckoutDialog.deliveryFee,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const RiderTips(),
                  const SizedBox(height: 24),
                  RiderRecentDeliveries(
                    orders: recentDeliveries,
                    feePerDelivery: CartCheckoutDialog.deliveryFee,
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Available orders',
                          style: TextStyle(
                            color: _riderInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${availableOrders.length} available',
                        style: const TextStyle(
                          color: _riderMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (availableOrders.isEmpty)
                    const _NoAvailableOrdersCard()
                  else
                    ...availableOrders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FadeSlideIn(child: _DeliveryCard(
                          order: order,
                          enabled: _isOnline,
                          riderUsername: riderUsername,
                          isAvailable: true,
                        )),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Your deliveries',
                          style: TextStyle(
                            color: _riderInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${activeOrders.length} active',
                        style: const TextStyle(
                          color: _riderMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (activeOrders.isEmpty)
                    const _NoDeliveriesCard()
                  else
                    ...activeOrders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FadeSlideIn(child: _DeliveryCard(
                          order: order,
                          enabled: _isOnline,
                          riderUsername: riderUsername,
                          isAvailable: false,
                        )),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }
}

class _RiderWelcomeCard extends StatelessWidget {
  const _RiderWelcomeCard({
    required this.riderName,
    required this.isOnline,
    required this.onStatusChanged,
  });

  final String riderName;
  final bool isOnline;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF23866A), Color(0xFF155B49)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(username: riderName, size: 60, editable: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready for your next trip?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Welcome back, ${_displayName(riderName)}.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: isOnline ? const Color(0xFF9AF0C9) : Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    isOnline ? 'You are online' : 'You are offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: isOnline,
                  onChanged: onStatusChanged,
                  activeTrackColor: const Color(0xFF9AF0C9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderStatCard extends StatelessWidget {
  const _RiderStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE2F2EC),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _riderAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _riderInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    color: _riderMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatefulWidget {
  const _DeliveryCard({
    required this.order,
    required this.enabled,
    required this.riderUsername,
    required this.isAvailable,
  });

  final CustomerOrder order;
  final bool enabled;
  final String riderUsername;
  final bool isAvailable;

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  Uint8List? _deliveryProofBytes;

  Future<void> _importDeliveryProof() async {
    final canUseCamera =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                'Add delivery proof',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Choose a photo before completing this delivery.'),
            ),
            if (canUseCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image == null || !context.mounted) return;

      final proofBytes = await image.readAsBytes();
      if (!context.mounted) return;
      if (proofBytes.isEmpty) {
        _showProofError('The selected photo is empty. Choose another.');
        return;
      }
      setState(() => _deliveryProofBytes = proofBytes);
    } on PlatformException catch (error) {
      if (context.mounted) {
        _showProofError(
          error.message ?? 'Unable to access photos. Check app permissions.',
        );
      }
    }
  }

  /// Opens Google Maps with turn-by-turn directions from the rider's
  /// current location to the customer's delivery address.
  Future<void> _openDirections() async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': widget.order.deliveryAddress,
      'travelmode': 'driving',
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _showProofError('Could not open Google Maps.');
    } catch (_) {
      if (mounted) _showProofError('Could not open Google Maps.');
    }
  }

  void _markDelivered() {
    final proofBytes = _deliveryProofBytes;
    if (proofBytes == null) return;
    final completed = OrderDatabase.instance.completeDelivery(
      widget.order.id,
      widget.riderUsername,
      proofBytes: proofBytes,
    );
    if (!completed) {
      _showProofError('This delivery could not be completed. Please try again.');
    }
  }

  void _showProofError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isOnTheWay = widget.order.status == 'On the way';
    final actionLabel = widget.isAvailable
        ? 'Accept order'
        : isOnTheWay
        ? 'Mark as delivered'
        : 'Pick up order';
    final totalItems = widget.order.items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.order.id,
                  style: const TextStyle(
                    color: _riderInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(status: widget.order.status),
            ],
          ),
          const SizedBox(height: 15),
          if (!widget.isAvailable) ...[
            const _DeliveryDetail(
              icon: Icons.assignment_turned_in_outlined,
              text: 'Accepted by you',
            ),
            const SizedBox(height: 9),
          ],
          _DeliveryDetail(
            icon: Icons.person_outline_rounded,
            text: widget.order.customerName,
          ),
          const SizedBox(height: 9),
          _DeliveryDetail(
            icon: Icons.location_on_outlined,
            text: widget.order.deliveryAddress,
          ),
          const SizedBox(height: 9),
          _DeliveryDetail(
            icon: Icons.shopping_bag_outlined,
            text:
                '$totalItems ${totalItems == 1 ? 'item' : 'items'} · '
                '${widget.order.items.map((item) => item.name).join(', ')}',
          ),
          if (!widget.isAvailable) ...[
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: _openDirections,
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Get directions to customer'),
              style: FilledButton.styleFrom(
                foregroundColor: _riderAccent,
                backgroundColor: const Color(0xFFE2F2EC),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
          if (isOnTheWay) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: widget.enabled ? _importDeliveryProof : null,
              icon: Icon(
                _deliveryProofBytes == null
                    ? Icons.add_a_photo_outlined
                    : Icons.change_circle_outlined,
              ),
              label: Text(
                _deliveryProofBytes == null
                    ? 'Add delivery photo (required)'
                    : 'Change delivery photo',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _riderAccent,
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: Color(0xFFDDE8E3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            if (_deliveryProofBytes case final proofBytes?) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.memory(
                  proofBytes,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
          if (isOnTheWay && _deliveryProofBytes == null) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: _riderMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Add a photo of the delivered order first. '
                    '"Mark as delivered" unlocks after the photo is added.',
                    style: TextStyle(color: _riderMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '\$${widget.order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _riderInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: !widget.enabled ||
                        (isOnTheWay && _deliveryProofBytes == null)
                    ? null
                    : () {
                        if (widget.isAvailable) {
                          OrderDatabase.instance.acceptOrder(
                            widget.order.id,
                            widget.riderUsername,
                          );
                        } else if (isOnTheWay) {
                          _markDelivered();
                        } else {
                          OrderDatabase.instance.startDelivery(
                            widget.order.id,
                            widget.riderUsername,
                          );
                        }
                      },
                icon: Icon(
                  widget.isAvailable
                      ? Icons.check_circle_outline_rounded
                      : isOnTheWay
                      ? Icons.check_circle_outline_rounded
                      : Icons.directions_bike_rounded,
                  size: 19,
                ),
                label: Text(actionLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: _riderAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8E5),
                  disabledForegroundColor: _riderMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetail extends StatelessWidget {
  const _DeliveryDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: _riderAccent),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _riderMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final inTransit = status == 'On the way';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inTransit ? const Color(0xFFFFF2D9) : const Color(0xFFE2F2EC),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: inTransit ? const Color(0xFF8A5A00) : _riderAccent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NoDeliveriesCard extends StatelessWidget {
  const _NoDeliveriesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 42, color: _riderAccent),
          SizedBox(height: 12),
          Text(
            'No deliveries right now',
            style: TextStyle(
              color: _riderInk,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'New orders will show up here when they are ready.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _riderMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _NoAvailableOrdersCard extends StatelessWidget {
  const _NoAvailableOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4ECE8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: _riderAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No orders are waiting for a rider right now.',
              style: TextStyle(color: _riderMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _riderInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _riderAccent),
    filled: true,
    fillColor: const Color(0xFFF5F8F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFDDE8E3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFDDE8E3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: _riderAccent, width: 1.5),
    ),
  );
}

class _RiderRequirementsCard extends StatelessWidget {
  const _RiderRequirementsCard({required this.vehicleType});

  final String vehicleType;

  @override
  Widget build(BuildContext context) {
    final requiresLicense = vehicleType != 'Bicycle';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requirements to prepare',
            style: TextStyle(
              color: _riderInk,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Have these ready for partner verification:',
            style: TextStyle(color: _riderMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          const _RiderRequirementItem(
            text: 'Valid government-issued ID',
            icon: Icons.badge_outlined,
          ),
          if (requiresLicense)
            const _RiderRequirementItem(
              text: 'Valid driver’s license, if required for your vehicle',
              icon: Icons.credit_card_outlined,
            ),
          if (vehicleType == 'Motorcycle')
            const _RiderRequirementItem(
              text: 'Motorcycle registration documents',
              icon: Icons.description_outlined,
            ),
          const _RiderRequirementItem(
            text: 'Any other documents requested during onboarding',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 10),
          const Text(
            'Verification, training or orientation may also be required. '
            'Requirements can change; confirm them through the official '
            'partner sign-up process.',
            style: TextStyle(color: _riderMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _RiderRequirementItem extends StatelessWidget {
  const _RiderRequirementItem({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _riderAccent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _riderInk,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderBackgroundOrb extends StatelessWidget {
  const _RiderBackgroundOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFB9DCCF).withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

bool _isActiveDelivery(String status) =>
    status == 'Pending' || status == 'Preparing' || status == 'On the way';

bool _isReadyForRider(String status) =>
    status == 'Pending' || status == 'Preparing';

String _displayName(String username) {
  if (username.isEmpty) return 'Rider';
  return username[0].toUpperCase() + username.substring(1);
}
