/// Kitchen order and its lifecycle. Statuses advance strictly forward.
enum OrderStatus { incoming, cooking, ready, pickedUp }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.incoming => 'Incoming',
        OrderStatus.cooking => 'Cooking',
        OrderStatus.ready => 'Ready',
        OrderStatus.pickedUp => 'Picked up',
      };

  /// The next status, or null if this is terminal.
  OrderStatus? get next => switch (this) {
        OrderStatus.incoming => OrderStatus.cooking,
        OrderStatus.cooking => OrderStatus.ready,
        OrderStatus.ready => OrderStatus.pickedUp,
        OrderStatus.pickedUp => null,
      };
}

class Order {
  final String id;
  final String table;
  final List<String> items;
  final OrderStatus status;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.table,
    required this.items,
    required this.status,
    required this.updatedAt,
  });

  Order copyWith({OrderStatus? status, DateTime? updatedAt}) => Order(
        id: id,
        table: table,
        items: items,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'items': items,
        'status': status.name,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        table: j['table'] as String,
        items: (j['items'] as List).cast<String>(),
        status: OrderStatus.values.byName(j['status'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

/// A status change waiting to be synced to the backend (survives offline + reload).
class PendingAction {
  final String orderId;
  final OrderStatus target;
  final DateTime at;

  const PendingAction({required this.orderId, required this.target, required this.at});

  Map<String, dynamic> toJson() =>
      {'orderId': orderId, 'target': target.name, 'at': at.toIso8601String()};

  factory PendingAction.fromJson(Map<String, dynamic> j) => PendingAction(
        orderId: j['orderId'] as String,
        target: OrderStatus.values.byName(j['target'] as String),
        at: DateTime.parse(j['at'] as String),
      );
}
