import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, provider, admin }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImage;
  final String? phone;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    this.phone,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      profileImage: map['profileImage'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'profileImage': profileImage,
      'phone': phone,
    };
  }

  AppUser copyWith({
    String? name,
    String? profileImage,
    String? phone,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
    );
  }
}

class ProviderProfile {
  final String providerId;
  final String businessName;
  final String ownerName;
  final String category;
  final double rating;
  final int reviewsCount;
  final double distance; // Dynamically computed, not in DB
  final String address;
  final String phone;
  final String whatsapp;
  final String email;
  final double latitude;
  final double longitude;
  final bool isVerified;
  final bool isAvailable;
  final double startingPrice;
  final int experienceYears;
  final String workingHours;
  final String serviceArea;
  final String? profileImage;

  ProviderProfile({
    required this.providerId,
    required this.businessName,
    required this.ownerName,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    this.distance = 0.0,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.latitude,
    required this.longitude,
    this.isVerified = false,
    this.isAvailable = true,
    required this.startingPrice,
    required this.experienceYears,
    required this.workingHours,
    required this.serviceArea,
    this.profileImage,
  });

  factory ProviderProfile.fromMap(Map<String, dynamic> map) {
    return ProviderProfile(
      providerId: map['providerId'] ?? '',
      businessName: map['businessName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      email: map['email'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      isVerified: map['isVerified'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      startingPrice: (map['startingPrice'] ?? 0.0).toDouble(),
      experienceYears: map['experienceYears'] ?? 0,
      workingHours: map['workingHours'] ?? '9:00 AM - 6:00 PM',
      serviceArea: map['serviceArea'] ?? 'Within 5 km',
      profileImage: map['profileImage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'businessName': businessName,
      'ownerName': ownerName,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isAvailable': isAvailable,
      'startingPrice': startingPrice,
      'experienceYears': experienceYears,
      'workingHours': workingHours,
      'serviceArea': serviceArea,
      'profileImage': profileImage,
    };
  }

  ProviderProfile copyWith({
    double? rating,
    int? reviewsCount,
    double? distance,
    bool? isVerified,
    bool? isAvailable,
    String? profileImage,
  }) {
    return ProviderProfile(
      providerId: providerId,
      businessName: businessName,
      ownerName: ownerName,
      category: category,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      distance: distance ?? this.distance,
      address: address,
      phone: phone,
      whatsapp: whatsapp,
      email: email,
      latitude: latitude,
      longitude: longitude,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      startingPrice: startingPrice,
      experienceYears: experienceYears,
      workingHours: workingHours,
      serviceArea: serviceArea,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

enum BookingStatus { pending, accepted, onTheWay, inProgress, completed, cancelled }

class Booking {
  final String id;
  final String customerId;
  final String customerName;
  final String providerId;
  final String providerBusinessName;
  final String category;
  final DateTime dateTime;
  final String timeSlot;
  final String description;
  final BookingStatus status;
  final double cost;
  final String? reviewText;
  final double? reviewRating;
  final List<String> statusTimeline; // e.g. "Pending: 10:00 AM", "Accepted: 10:15 AM"

  Booking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.providerBusinessName,
    required this.category,
    required this.dateTime,
    required this.timeSlot,
    required this.description,
    required this.status,
    required this.cost,
    this.reviewText,
    this.reviewRating,
    required this.statusTimeline,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      providerId: map['providerId'] ?? '',
      providerBusinessName: map['providerBusinessName'] ?? '',
      category: map['category'] ?? '',
      dateTime: (map['dateTime'] is Timestamp)
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.parse(map['dateTime']),
      timeSlot: map['timeSlot'] ?? '',
      description: map['description'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      cost: (map['cost'] ?? 0.0).toDouble(),
      reviewText: map['reviewText'],
      reviewRating: map['reviewRating'] != null ? (map['reviewRating']).toDouble() : null,
      statusTimeline: List<String>.from(map['statusTimeline'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'providerId': providerId,
      'providerBusinessName': providerBusinessName,
      'category': category,
      'dateTime': Timestamp.fromDate(dateTime),
      'timeSlot': timeSlot,
      'description': description,
      'status': status.name,
      'cost': cost,
      'reviewText': reviewText,
      'reviewRating': reviewRating,
      'statusTimeline': statusTimeline,
    };
  }

  Booking copyWith({
    BookingStatus? status,
    double? cost,
    String? reviewText,
    double? reviewRating,
    List<String>? statusTimeline,
  }) {
    return Booking(
      id: id,
      customerId: customerId,
      customerName: customerName,
      providerId: providerId,
      providerBusinessName: providerBusinessName,
      category: category,
      dateTime: dateTime,
      timeSlot: timeSlot,
      description: description,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      reviewText: reviewText ?? this.reviewText,
      reviewRating: reviewRating ?? this.reviewRating,
      statusTimeline: statusTimeline ?? this.statusTimeline,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}
