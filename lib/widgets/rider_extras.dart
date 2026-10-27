import 'package:flutter/material.dart';

import '../database/order_database.dart';

const _accent = Color(0xFF23866A);
const _ink = Color(0xFF16352B);
const _muted = Color(0xFF71827D);
const _border = Color(0xFFE4ECE8);

/// Earnings and daily-goal card for the rider.
class RiderEarningsCard extends StatelessWidget {
  const RiderEarningsCard({
    super.key,
    required this.completed,
    required this.active,
    required this.feePerDelivery,
    this.dailyGoal = 10,
  });

  final int completed;
  final int active;
  final double feePerDelivery;
  final int dailyGoal;

  @override
  Widget build(BuildContext context) {
    final progress = (completed / dailyGoal).clamp(0.0, 1.0).toDouble();
    final earned = completed * feePerDelivery;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF16352B), Color(0xFF23866A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery earnings',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${earned.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${feePerDelivery.toStringAsFixed(0)} per delivery · '
                  '$active on the way',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed/$dailyGoal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'daily goal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Short safety / service tips for riders.
class RiderTips extends StatelessWidget {
  const RiderTips({super.key});

  static const _tips = [
    (Icons.verified_user_outlined, 'Check the address before pickup'),
    (Icons.camera_alt_outlined, 'Take a clear photo as proof'),
    (Icons.local_fire_department_outlined, 'Keep pizza flat and hot'),
    (Icons.speed_rounded, 'Ride safe, never rush'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (icon, text) = _tips[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _accent),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

/// The rider's last few completed deliveries.
class RiderRecentDeliveries extends StatelessWidget {
  const RiderRecentDeliveries({
    super.key,
    required this.orders,
    required this.feePerDelivery,
  });

  final List<CustomerOrder> orders;
  final double feePerDelivery;

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent deliveries',
          style: TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final order in orders.take(3))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: _accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${order.deliveryAddress} · ${_time(order.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+₱${feePerDelivery.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
      ],
    );
  }
}
