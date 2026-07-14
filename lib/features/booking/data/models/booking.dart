import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String id,
    required String userId,
    required String tripId,
    required List<String> seats,
    required double totalPrice,
    required String paymentMethod,
    required String paymentStatus,
    required String ticketQrCode,
    required DateTime createdAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? json['tripId'] as String? ?? '',
      seats: (json['seats'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      totalPrice: ((json['total_price'] ?? json['totalPrice'] ?? 0.0) as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? json['paymentStatus'] as String? ?? '',
      ticketQrCode: json['ticket_qr_code'] as String? ?? json['ticketQrCode'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
