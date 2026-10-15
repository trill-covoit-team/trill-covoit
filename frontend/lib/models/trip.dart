import 'package:latlong2/latlong.dart';

/// Représente un trajet proposé par un conducteur.
class Trip {
  final int tripId;
  final String departureAddress;
  final LatLng departureCoordinates;
  final String arrivalAddress;
  final LatLng arrivalCoordinates;
  final DateTime departureDatetime;
  final int offeredSeats;
  final String status;
  final TripDriver driver;
  final TripVehicle vehicle;

  const Trip({
    required this.tripId,
    required this.departureAddress,
    required this.departureCoordinates,
    required this.arrivalAddress,
    required this.arrivalCoordinates,
    required this.departureDatetime,
    required this.offeredSeats,
    required this.status,
    required this.driver,
    required this.vehicle,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'] as int,
      departureAddress: json['departureAddress'] as String,
      departureCoordinates: LatLng(
        (json['departureLatitude'] as num).toDouble(),
        (json['departureLongitude'] as num).toDouble(),
      ),
      arrivalAddress: json['arrivalAddress'] as String,
      arrivalCoordinates: LatLng(
        (json['arrivalLatitude'] as num).toDouble(),
        (json['arrivalLongitude'] as num).toDouble(),
      ),
      departureDatetime: DateTime.parse(json['departureDatetime'] as String),
      offeredSeats: json['offeredSeats'] as int,
      status: json['status'] as String,
      driver: TripDriver.fromJson(json['driver'] as Map<String, dynamic>),
      vehicle: TripVehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
    );
  }
}

class TripDriver {
  final int userId;
  final String firstName;
  final String lastName;
  final String? photoUrl;

  const TripDriver({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
  });

  factory TripDriver.fromJson(Map<String, dynamic> json) {
    return TripDriver(
      userId: json['userId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

class TripVehicle {
  final int vehicleId;
  final String brand;
  final String model;
  final int passengerCapacity;
  final String status;

  const TripVehicle({
    required this.vehicleId,
    required this.brand,
    required this.model,
    required this.passengerCapacity,
    required this.status,
  });

  factory TripVehicle.fromJson(Map<String, dynamic> json) {
    return TripVehicle(
      vehicleId: json['vehicleId'] as int,
      brand: json['brand'] as String,
      model: json['model'] as String,
      passengerCapacity: json['passengerCapacity'] as int,
      status: json['status'] as String,
    );
  }
}