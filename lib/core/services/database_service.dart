import 'dart:async';
import 'dart:math';
import '../models/models.dart';

abstract class DatabaseService {
  // Auth & User details
  Future<AppUser?> getUser(String uid);
  Future<void> createUser(AppUser user);
  Future<void> updateUser(AppUser user);

  // Provider methods
  Future<ProviderProfile?> getProviderProfile(String providerId);
  Future<void> createOrUpdateProviderProfile(ProviderProfile profile);
  Future<List<ProviderProfile>> getNearbyProviders(double userLat, double userLng, String category);
  Stream<List<ProviderProfile>> getNearbyProvidersStream(double userLat, double userLng, String category);

  // Booking methods
  Future<void> createBooking(Booking booking);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  Future<void> addBookingReview(String bookingId, double rating, String text);
  Stream<List<Booking>> getCustomerBookingsStream(String customerId);
  Stream<List<Booking>> getProviderBookingsStream(String providerId);
  Stream<Booking?> getBookingStream(String bookingId);

  // Chat methods
  Future<void> sendChatMessage(ChatMessage message);
  Stream<List<ChatMessage>> getChatMessagesStream(String userA, String userB);
  Stream<List<AppUser>> getActiveChatPartnersStream(String userId);

  // Admin methods
  Future<List<ProviderProfile>> getUnverifiedProviders();
  Future<void> approveProvider(String providerId);
  Future<Map<String, dynamic>> getAdminStats();
}

class MockDatabaseService implements DatabaseService {
  // In-memory data store
  final Map<String, AppUser> _users = {};
  final Map<String, ProviderProfile> _providers = {};
  final Map<String, Booking> _bookings = {};
  final List<ChatMessage> _messages = [];

  // Stream controllers for real-time reactivity
  final _bookingsStreamController = StreamController<List<Booking>>.broadcast();
  final _messagesStreamController = StreamController<List<ChatMessage>>.broadcast();
  final _providersStreamController = StreamController<List<ProviderProfile>>.broadcast();

  MockDatabaseService() {
    _initMockData();
  }

  void _initMockData() {
    // 1. Setup Default Admin
    final adminUser = AppUser(
      uid: 'admin_1',
      email: 'admin@fixora.com',
      name: 'Super Admin',
      role: UserRole.admin,
      phone: '+919999988888',
    );
    _users[adminUser.uid] = adminUser;

    // 2. Setup standard users/providers
    // Location: Connaught Place, New Delhi is 28.6304, 77.2177
    final List<Map<String, dynamic>> rawProviders = [
      {
        'id': 'prov_elec_1',
        'businessName': 'ElectroFix Specialists',
        'ownerName': 'Rajesh Sharma',
        'category': 'Electrician',
        'rating': 4.8,
        'reviewsCount': 24,
        'address': 'E-Block, Connaught Place, New Delhi',
        'phone': '+919876543210',
        'whatsapp': '+919876543210',
        'email': 'rajesh@electrofix.com',
        'lat': 28.6315,
        'lng': 77.2185,
        'isVerified': true,
        'startingPrice': 199.0,
        'experience': 8,
        'workingHours': '8:00 AM - 8:00 PM',
      },
      {
        'id': 'prov_plumb_1',
        'businessName': 'Super Plumbers & Co',
        'ownerName': 'Amit Verma',
        'category': 'Plumber',
        'rating': 4.5,
        'reviewsCount': 19,
        'address': 'F-Block, Inner Circle, Connaught Place',
        'phone': '+919811223344',
        'whatsapp': '+919811223344',
        'email': 'amit@superplumb.com',
        'lat': 28.6292,
        'lng': 77.2160,
        'isVerified': true,
        'startingPrice': 149.0,
        'experience': 5,
        'workingHours': '9:00 AM - 7:00 PM',
      },
      {
        'id': 'prov_mech_1',
        'businessName': 'Express Auto Mechanics',
        'ownerName': 'Gurpreet Singh',
        'category': 'Mechanic',
        'rating': 4.9,
        'reviewsCount': 42,
        'address': 'Barakhamba Road, Near Metro Station, New Delhi',
        'phone': '+919922334455',
        'whatsapp': '+919922334455',
        'email': 'gurpreet@expressauto.com',
        'lat': 28.6328,
        'lng': 77.2215,
        'isVerified': true,
        'startingPrice': 299.0,
        'experience': 12,
        'workingHours': '8:00 AM - 10:00 PM',
      },
      {
        'id': 'prov_ac_1',
        'businessName': 'ChillWave AC Repair & Services',
        'ownerName': 'Vikram Rathore',
        'category': 'AC Repair',
        'rating': 4.2,
        'reviewsCount': 8,
        'address': 'Janpath, Connaught Place, New Delhi',
        'phone': '+919898989898',
        'whatsapp': '+919898989898',
        'email': 'vikram@chillwave.com',
        'lat': 28.6275,
        'lng': 77.2190,
        'isVerified': false, // Needs admin approval!
        'startingPrice': 399.0,
        'experience': 4,
        'workingHours': '9:00 AM - 6:00 PM',
      },
      {
        'id': 'prov_clean_1',
        'businessName': 'Sparkle Squad Home Cleaners',
        'ownerName': 'Priya Das',
        'category': 'Cleaner',
        'rating': 4.7,
        'reviewsCount': 31,
        'address': 'KG Marg, Connaught Place, New Delhi',
        'phone': '+919777788888',
        'whatsapp': '+919777788888',
        'email': 'priya@sparklesquad.com',
        'lat': 28.6260,
        'lng': 77.2150,
        'isVerified': true,
        'startingPrice': 499.0,
        'experience': 6,
        'workingHours': '7:00 AM - 9:00 PM',
      },
    ];

    for (var raw in rawProviders) {
      final String id = raw['id'];
      
      // Save AppUser credentials
      final user = AppUser(
        uid: id,
        email: raw['email'],
        name: raw['ownerName'],
        role: UserRole.provider,
        phone: raw['phone'],
      );
      _users[id] = user;

      // Save Provider Profile
      final profile = ProviderProfile(
        providerId: id,
        businessName: raw['businessName'],
        ownerName: raw['ownerName'],
        category: raw['category'],
        rating: raw['rating'],
        reviewsCount: raw['reviewsCount'],
        address: raw['address'],
        phone: raw['phone'],
        whatsapp: raw['whatsapp'],
        email: raw['email'],
        latitude: raw['lat'],
        longitude: raw['lng'],
        isVerified: raw['isVerified'],
        startingPrice: raw['startingPrice'],
        experienceYears: raw['experience'],
        workingHours: raw['workingHours'],
        serviceArea: 'Within 8 km',
      );
      _providers[id] = profile;
    }
  }

  // Auth Methods
  @override
  Future<AppUser?> getUser(String uid) async {
    return _users[uid];
  }

  @override
  Future<void> createUser(AppUser user) async {
    _users[user.uid] = user;
  }

  @override
  Future<void> updateUser(AppUser user) async {
    _users[user.uid] = user;
  }

  // Provider Profile Methods
  @override
  Future<ProviderProfile?> getProviderProfile(String providerId) async {
    return _providers[providerId];
  }

  @override
  Future<void> createOrUpdateProviderProfile(ProviderProfile profile) async {
    _providers[profile.providerId] = profile;
    _providersStreamController.add(_providers.values.toList());
  }

  @override
  Future<List<ProviderProfile>> getNearbyProviders(double userLat, double userLng, String category) async {
    List<ProviderProfile> matched = [];
    _providers.forEach((id, p) {
      if ((category.isEmpty || p.category.toLowerCase() == category.toLowerCase()) && p.isVerified) {
        // Distance calculation
        double dist = _calculateDistance(userLat, userLng, p.latitude, p.longitude);
        matched.add(p.copyWith(distance: dist));
      }
    });
    // Sort by nearest
    matched.sort((a, b) => a.distance.compareTo(b.distance));
    return matched;
  }

  @override
  Stream<List<ProviderProfile>> getNearbyProvidersStream(double userLat, double userLng, String category) {
    // Create immediate search yield
    final controller = StreamController<List<ProviderProfile>>();
    getNearbyProviders(userLat, userLng, category).then((list) {
      if (!controller.isClosed) {
        controller.add(list);
      }
    });
    
    // Listen to changes
    _providersStreamController.stream.listen((allProviders) {
      List<ProviderProfile> matched = [];
      for (var p in allProviders) {
        if ((category.isEmpty || p.category.toLowerCase() == category.toLowerCase()) && p.isVerified) {
          double dist = _calculateDistance(userLat, userLng, p.latitude, p.longitude);
          matched.add(p.copyWith(distance: dist));
        }
      }
      matched.sort((a, b) => a.distance.compareTo(b.distance));
      if (!controller.isClosed) {
        controller.add(matched);
      }
    });

    return controller.stream;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Bookings Methods
  @override
  Future<void> createBooking(Booking booking) async {
    _bookings[booking.id] = booking;
    _bookingsStreamController.add(_bookings.values.toList());
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    final b = _bookings[bookingId];
    if (b != null) {
      List<String> timeline = List.from(b.statusTimeline);
      String timeStr = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      timeline.add("${_statusLabel(status)}: $timeStr");
      
      _bookings[bookingId] = b.copyWith(status: status, statusTimeline: timeline);
      _bookingsStreamController.add(_bookings.values.toList());

      // Simulate live updates for tracking: if 'accepted', automatically transition to 'onTheWay' and 'inProgress' in mock background
      if (status == BookingStatus.accepted) {
        Future.delayed(const Duration(seconds: 8), () {
          updateBookingStatus(bookingId, BookingStatus.onTheWay);
        });
      } else if (status == BookingStatus.onTheWay) {
        Future.delayed(const Duration(seconds: 8), () {
          updateBookingStatus(bookingId, BookingStatus.inProgress);
        });
      }
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return "Booking Submitted";
      case BookingStatus.accepted: return "Accepted by Provider";
      case BookingStatus.onTheWay: return "Provider is On The Way";
      case BookingStatus.inProgress: return "Service Started";
      case BookingStatus.completed: return "Service Completed";
      case BookingStatus.cancelled: return "Booking Cancelled";
    }
  }

  @override
  Future<void> addBookingReview(String bookingId, double rating, String text) async {
    final b = _bookings[bookingId];
    if (b != null) {
      _bookings[bookingId] = b.copyWith(reviewRating: rating, reviewText: text);
      _bookingsStreamController.add(_bookings.values.toList());

      // Update provider profile rating average
      final p = _providers[b.providerId];
      if (p != null) {
        double newRating = ((p.rating * p.reviewsCount) + rating) / (p.reviewsCount + 1);
        _providers[b.providerId] = p.copyWith(
          rating: double.parse(newRating.toStringAsFixed(1)),
          reviewsCount: p.reviewsCount + 1,
        );
        _providersStreamController.add(_providers.values.toList());
      }
    }
  }

  @override
  Stream<List<Booking>> getCustomerBookingsStream(String customerId) {
    final controller = StreamController<List<Booking>>.broadcast();
    
    // Add current matches
    controller.add(_bookings.values.where((b) => b.customerId == customerId).toList());
    
    // Stream updates
    final sub = _bookingsStreamController.stream.listen((list) {
      controller.add(list.where((b) => b.customerId == customerId).toList());
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Stream<List<Booking>> getProviderBookingsStream(String providerId) {
    final controller = StreamController<List<Booking>>.broadcast();
    controller.add(_bookings.values.where((b) => b.providerId == providerId).toList());
    
    final sub = _bookingsStreamController.stream.listen((list) {
      controller.add(list.where((b) => b.providerId == providerId).toList());
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Stream<Booking?> getBookingStream(String bookingId) {
    final controller = StreamController<Booking?>.broadcast();
    controller.add(_bookings[bookingId]);
    
    final sub = _bookingsStreamController.stream.listen((list) {
      final matches = list.where((b) => b.id == bookingId);
      controller.add(matches.isNotEmpty ? matches.first : null);
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  // Chat Methods
  @override
  Future<void> sendChatMessage(ChatMessage message) async {
    _messages.add(message);
    _messagesStreamController.add(_messages);
  }

  @override
  Stream<List<ChatMessage>> getChatMessagesStream(String userA, String userB) {
    final controller = StreamController<List<ChatMessage>>.broadcast();
    
    var filter = _messages.where((m) =>
      (m.senderId == userA && m.receiverId == userB) ||
      (m.senderId == userB && m.receiverId == userA)
    ).toList();
    filter.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    controller.add(filter);

    final sub = _messagesStreamController.stream.listen((list) {
      var updated = list.where((m) =>
        (m.senderId == userA && m.receiverId == userB) ||
        (m.senderId == userB && m.receiverId == userA)
      ).toList();
      updated.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      controller.add(updated);
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Stream<List<AppUser>> getActiveChatPartnersStream(String userId) {
    final controller = StreamController<List<AppUser>>.broadcast();
    
    _emitPartners(controller, userId);
    final sub = _messagesStreamController.stream.listen((_) {
      _emitPartners(controller, userId);
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  void _emitPartners(StreamController<List<AppUser>> controller, String userId) {
    final Set<String> partnerIds = {};
    for (var m in _messages) {
      if (m.senderId == userId) partnerIds.add(m.receiverId);
      if (m.receiverId == userId) partnerIds.add(m.senderId);
    }
    
    List<AppUser> partners = [];
    for (var id in partnerIds) {
      final user = _users[id];
      if (user != null) {
        partners.add(user);
      }
    }
    controller.add(partners);
  }

  // Admin Methods
  @override
  Future<List<ProviderProfile>> getUnverifiedProviders() async {
    return _providers.values.where((p) => !p.isVerified).toList();
  }

  @override
  Future<void> approveProvider(String providerId) async {
    final p = _providers[providerId];
    if (p != null) {
      _providers[providerId] = p.copyWith(isVerified: true);
      _providersStreamController.add(_providers.values.toList());
    }
  }

  @override
  Future<Map<String, dynamic>> getAdminStats() async {
    int totalUsers = _users.values.where((u) => u.role == UserRole.customer).length;
    int totalProviders = _providers.length;
    int activeBookings = _bookings.values.where((b) => 
      b.status != BookingStatus.completed && b.status != BookingStatus.cancelled
    ).length;
    
    double revenue = 0.0;
    _bookings.values.forEach((b) {
      if (b.status == BookingStatus.completed) {
        revenue += (b.cost * 0.1); // Admin takes 10% commission
      }
    });

    return {
      'totalUsers': totalUsers,
      'totalProviders': totalProviders,
      'activeBookings': activeBookings,
      'revenue': revenue,
    };
  }
}
