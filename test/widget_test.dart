import 'package:flutter_test/flutter_test.dart';
import 'package:fixora/core/models/models.dart';
import 'package:fixora/core/services/database_service.dart';

void main() {
  group('Fixora App Core Unit Tests', () {
    late MockDatabaseService dbSvc;

    setUp(() {
      dbSvc = MockDatabaseService();
    });

    test('Loads pre-populated providers successfully', () async {
      final providers = await dbSvc.getNearbyProviders(28.6304, 77.2177, '');
      expect(providers.isNotEmpty, true);
      expect(providers.length, greaterThanOrEqualTo(4)); // Verified pre-populated list
    });

    test('Filters providers by category correctly', () async {
      final electricians = await dbSvc.getNearbyProviders(28.6304, 77.2177, 'Electrician');
      expect(electricians.every((p) => p.category == 'Electrician'), true);
      
      final plumbers = await dbSvc.getNearbyProviders(28.6304, 77.2177, 'Plumber');
      expect(plumbers.every((p) => p.category == 'Plumber'), true);
    });

    test('Creates and retrieves new bookings', () async {
      final newBooking = Booking(
        id: 'test_book_id',
        customerId: 'test_customer',
        customerName: 'Test Customer',
        providerId: 'prov_elec_1',
        providerBusinessName: 'ElectroFix Specialists',
        category: 'Electrician',
        dateTime: DateTime.now(),
        timeSlot: '10:00 AM - 12:00 PM',
        description: 'Test electrical problem description',
        status: BookingStatus.pending,
        cost: 199.0,
        statusTimeline: ['Booking Submitted'],
      );

      // Get the stream and set up the listener FIRST
      final stream = dbSvc.getCustomerBookingsStream('test_customer');
      final futureList = stream.firstWhere((list) => list.isNotEmpty);

      // Trigger the creation which fires the stream update
      await dbSvc.createBooking(newBooking);

      // Await the update
      final currentList = await futureList;
      
      expect(currentList.length, 1);
      expect(currentList.first.id, 'test_book_id');
      expect(currentList.first.cost, 199.0);
    });
  });
}
