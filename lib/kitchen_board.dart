import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'state.dart';

class KitchenBoard extends ConsumerWidget {
  const KitchenBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bar Mleczny Nowa — kitchen'),
        actions: [
          if (state.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Chip(
                key: const Key('pending-chip'),
                label: Text('${state.pendingCount} queued'),
              ),
            ),
          TextButton.icon(
            key: const Key('online-toggle'),
            onPressed: notifier.toggleOnline,
            icon: Icon(state.online ? Icons.cloud_done : Icons.cloud_off),
            label: Text(state.online ? 'Online' : 'Offline'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final status in OrderStatus.values)
              Expanded(child: _StatusColumn(status: status)),
          ],
        ),
      ),
    );
  }
}

class _StatusColumn extends ConsumerWidget {
  const _StatusColumn({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider).byStatus(status);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('${status.label}  (${orders.length})',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [for (final o in orders) _OrderCard(order: o)],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = order.status.next;
    return Card(
      key: Key('order-${order.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order.id} · ${order.table}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(order.items.join(', ')),
            if (next != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  key: Key('advance-${order.id}'),
                  onPressed: () => ref.read(ordersProvider.notifier).advance(order.id),
                  child: Text('→ ${next.label}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
