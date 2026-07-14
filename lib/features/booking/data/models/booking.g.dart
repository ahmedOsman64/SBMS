// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingImpl _$$BookingImplFromJson(Map<String, dynamic> json) =>
    _$BookingImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tripId: json['tripId'] as String,
      seats: (json['seats'] as List<dynamic>).map((e) => e as String).toList(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      ticketQrCode: json['ticketQrCode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$BookingImplToJson(_$BookingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'tripId': instance.tripId,
      'seats': instance.seats,
      'totalPrice': instance.totalPrice,
      'paymentMethod': instance.paymentMethod,
      'paymentStatus': instance.paymentStatus,
      'ticketQrCode': instance.ticketQrCode,
      'createdAt': instance.createdAt.toIso8601String(),
    };
