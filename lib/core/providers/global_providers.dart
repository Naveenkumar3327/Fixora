import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../models/models.dart';

// Service providers
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final databaseServiceProvider = Provider<DatabaseService>((ref) => MockDatabaseService());

// Location states
final userLocationProvider = StateProvider<Position?>((ref) => null);
final userAddressProvider = StateProvider<String>((ref) => "Locating current position...");

// Active Auth State
final authStateProvider = StateProvider<AppUser?>((ref) => null);

// Selected role for registration flow
final registrationRoleProvider = StateProvider<UserRole>((ref) => UserRole.customer);

// Helper method to fetch address dynamically
final fetchAddressProvider = FutureProvider.family<String, Position>((ref, pos) async {
  final locSvc = ref.read(locationServiceProvider);
  return await locSvc.getAddressFromCoordinates(pos.latitude, pos.longitude);
});
