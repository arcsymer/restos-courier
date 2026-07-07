import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Provided in main() (and overridden in tests) so the notifier is synchronous.
final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('override prefsProvider in main()/tests');
});

class OrdersState {
  final List<Order> orders;
  final List<PendingAction> pending;
  final bool online;

  const OrdersState({required this.orders, required this.pending, required this.online});

  int get pendingCount => pending.length;

  List<Order> byStatus(OrderStatus s) => orders.where((o) => o.status == s).toList()
    ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

  OrdersState copyWith({List<Order>? orders, List<PendingAction>? pending, bool? online}) =>
      OrdersState(
        orders: orders ?? this.orders,
        pending: pending ?? this.pending,
        online: online ?? this.online,
      );
}

const _ordersKey = 'orders';
const _pendingKey = 'pending';

List<Order> _seed(DateTime now) => [
      Order(id: 'BMN-101', table: 'T4', items: ['Żurek', 'Kotlet schabowy'], status: OrderStatus.incoming, updatedAt: now),
      Order(id: 'BMN-102', table: 'T7', items: ['Pierogi ruskie', 'Kompot'], status: OrderStatus.cooking, updatedAt: now),
      Order(id: 'BMN-103', table: 'T2', items: ['Rosół', 'Naleśniki'], status: OrderStatus.ready, updatedAt: now),
      Order(id: 'BMN-104', table: 'T9', items: ['Bigos'], status: OrderStatus.incoming, updatedAt: now),
    ];

class OrdersNotifier extends Notifier<OrdersState> {
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  OrdersState build() {
    final ordersJson = _prefs.getString(_ordersKey);
    final pendingJson = _prefs.getString(_pendingKey);
    final orders = ordersJson == null
        ? _seed(DateTime.now())
        : (jsonDecode(ordersJson) as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
    final pending = pendingJson == null
        ? <PendingAction>[]
        : (jsonDecode(pendingJson) as List)
            .map((e) => PendingAction.fromJson(e as Map<String, dynamic>))
            .toList();
    return OrdersState(orders: orders, pending: pending, online: true);
  }

  /// Advance an order to its next status. The change is queued for sync; if we're online it
  /// flushes immediately, if offline it stays queued (and persisted) until reconnect.
  void advance(String orderId) {
    final idx = state.orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final next = state.orders[idx].status.next;
    if (next == null) return;

    final orders = [...state.orders];
    orders[idx] = orders[idx].copyWith(status: next, updatedAt: DateTime.now());
    final pending = [
      ...state.pending,
      PendingAction(orderId: orderId, target: next, at: DateTime.now()),
    ];
    state = state.copyWith(orders: orders, pending: pending);
    _persist();
    _sync();
  }

  void toggleOnline() {
    state = state.copyWith(online: !state.online);
    _sync();
  }

  /// When online, flush the queued actions to the backend. (Static demo: the flush is simulated —
  /// there is no live server on GitHub Pages — but the queue/persistence behaviour is real.)
  void _sync() {
    if (state.online && state.pending.isNotEmpty) {
      state = state.copyWith(pending: []);
      _persist();
    }
  }

  void _persist() {
    _prefs.setString(_ordersKey, jsonEncode(state.orders.map((o) => o.toJson()).toList()));
    _prefs.setString(_pendingKey, jsonEncode(state.pending.map((p) => p.toJson()).toList()));
  }
}

final ordersProvider =
    NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);
