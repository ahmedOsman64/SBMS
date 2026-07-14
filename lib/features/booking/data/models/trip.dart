import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String routeId,
    required String departureCity,
    required String arrivalCity,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required String busNumber,
    required int totalSeats,
    required int availableSeats,
    required List<String> occupiedSeats,
    required double price,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) {
    final routeData = json['routes'] as Map<String, dynamic>?;
    return Trip(
      id: json['id'] as String? ?? '',
      routeId: json['route_id'] as String? ?? json['routeId'] as String? ?? '',
      departureCity: routeData?['departure_city'] as String? ?? json['departureCity'] as String? ?? '',
      arrivalCity: routeData?['arrival_city'] as String? ?? json['arrivalCity'] as String? ?? '',
      departureTime: DateTime.parse(json['departure_time'] as String? ?? json['departureTime'] as String? ?? DateTime.now().toIso8601String()),
      arrivalTime: DateTime.parse(json['arrival_time'] as String? ?? json['arrivalTime'] as String? ?? DateTime.now().toIso8601String()),
      busNumber: json['bus_number'] as String? ?? json['busNumber'] as String? ?? '',
      totalSeats: ((json['total_seats'] ?? json['totalSeats'] ?? 40) as num).toInt(),
      availableSeats: ((json['available_seats'] ?? json['availableSeats'] ?? 40) as num).toInt(),
      occupiedSeats: (json['occupied_seats'] as List<dynamic>? ?? json['occupiedSeats'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      price: ((json['price'] ?? json['price'] ?? 0.0) as num).toDouble(),
    );
  }
}
