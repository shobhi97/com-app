import 'package:equatable/equatable.dart';

enum BellType { buy, sell, exit, adjust, alert }
enum BellPriority { normal, high, urgent }

extension BellTypeX on BellType {
  String get label => switch (this) {
        BellType.buy => 'BUY',
        BellType.sell => 'SELL',
        BellType.exit => 'EXIT',
        BellType.adjust => 'ADJUST',
        BellType.alert => 'ALERT',
      };
}

class Bell extends Equatable {
  final String id;
  final String createdByUserId;
  final String createdByName;
  final BellType type;
  final BellPriority priority;
  final String instrument; // e.g. NIFTY 24500 CE
  final double? price;
  final double? targetPrice;
  final double? stopLoss;
  final String message;
  final DateTime createdAt;
  final String? sessionId;

  const Bell({
    required this.id,
    required this.createdByUserId,
    required this.createdByName,
    required this.type,
    required this.priority,
    required this.instrument,
    this.price,
    this.targetPrice,
    this.stopLoss,
    required this.message,
    required this.createdAt,
    this.sessionId,
  });

  factory Bell.fromJson(Map<String, dynamic> json) => Bell(
        id: json['id'] as String,
        createdByUserId: json['created_by'] as String,
        createdByName: json['created_by_name'] as String? ?? 'Admin',
        type: BellType.values.byName(json['type'] as String? ?? 'alert'),
        priority: BellPriority.values.byName(json['priority'] as String? ?? 'normal'),
        instrument: json['instrument'] as String,
        price: (json['price'] as num?)?.toDouble(),
        targetPrice: (json['target_price'] as num?)?.toDouble(),
        stopLoss: (json['stop_loss'] as num?)?.toDouble(),
        message: json['message'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        sessionId: json['session_id'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'type': type.name,
        'priority': priority.name,
        'instrument': instrument,
        'price': price,
        'target_price': targetPrice,
        'stop_loss': stopLoss,
        'message': message,
        'session_id': sessionId,
      };

  @override
  List<Object?> get props => [id, type, instrument, price, createdAt];
}
