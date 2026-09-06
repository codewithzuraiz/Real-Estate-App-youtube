import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PropertyLocation {
  final String address;
  final String areaName;
  final String city;
  final double latitude;
  final double longitude;

  const PropertyLocation({
    required this.address,
    required this.areaName,
    required this.city,
    this.latitude = 31.5204, // Default Lahore coords
    this.longitude = 74.3587,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'areaName': areaName,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PropertyLocation.fromMap(Map<String, dynamic> map) {
    return PropertyLocation(
      address: map['address'] ?? '',
      areaName: map['areaName'] ?? '',
      city: map['city'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 31.5204,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 74.3587,
    );
  }

  PropertyLocation copyWith({
    String? address,
    String? areaName,
    String? city,
    double? latitude,
    double? longitude,
  }) {
    return PropertyLocation(
      address: address ?? this.address,
      areaName: areaName ?? this.areaName,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String get fullAddress => areaName.isNotEmpty ? '$address, $areaName, $city' : '$address, $city';
}

class AgentModel {
  final String id;
  final String name;
  final String agency;
  final String phone;
  final String email;
  final String avatarUrl;
  final bool isVerified;
  final double rating;
  final int reviewsCount;

  const AgentModel({
    required this.id,
    required this.name,
    this.agency = 'Prime Realty Group',
    required this.phone,
    required this.email,
    this.avatarUrl = '',
    this.isVerified = true,
    this.rating = 4.9,
    this.reviewsCount = 24,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'agency': agency,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'rating': rating,
      'reviewsCount': reviewsCount,
    };
  }

  factory AgentModel.fromMap(Map<String, dynamic> map) {
    return AgentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Real Estate Agent',
      agency: map['agency'] ?? 'Prime Realty Group',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      isVerified: map['isVerified'] ?? true,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 24,
    );
  }

  AgentModel copyWith({
    String? id,
    String? name,
    String? agency,
    String? phone,
    String? email,
    String? avatarUrl,
    bool? isVerified,
    double? rating,
    int? reviewsCount,
  }) {
    return AgentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      agency: agency ?? this.agency,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }
}

class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String purpose; // 'For Sale' or 'For Rent'
  final String propertyType; // 'House / Villa', 'Apartment', 'Commercial', 'Plot', 'Penthouse', 'Farmhouse', 'Office'
  final List<String> images;
  final String? videoUrl;
  final PropertyLocation location;
  final double area;
  final String areaUnit; // 'Marla', 'Kanal', 'Sq Ft', 'Sq Yd', 'Sq M'
  final int bedrooms;
  final int bathrooms;
  final List<String> amenities;
  final AgentModel agent;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewsCount;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'PKR',
    this.purpose = 'For Sale',
    required this.propertyType,
    this.images = const [],
    this.videoUrl,
    required this.location,
    required this.area,
    this.areaUnit = 'Marla',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.amenities = const [],
    required this.agent,
    this.isFeatured = false,
    required this.createdAt,
    this.updatedAt,
    this.viewsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'purpose': purpose,
      'propertyType': propertyType,
      'images': images,
      'videoUrl': videoUrl,
      'location': location.toMap(),
      'area': area,
      'areaUnit': areaUnit,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'agent': agent.toMap(),
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'viewsCount': viewsCount,
    };
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return PropertyModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'PKR',
      purpose: map['purpose'] ?? 'For Sale',
      propertyType: map['propertyType'] ?? 'House / Villa',
      images: (map['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      videoUrl: map['videoUrl'],
      location: PropertyLocation.fromMap(map['location'] is Map<String, dynamic> ? map['location'] : {}),
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      areaUnit: map['areaUnit'] ?? 'Marla',
      bedrooms: (map['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (map['bathrooms'] as num?)?.toInt() ?? 0,
      amenities: (map['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      agent: AgentModel.fromMap(map['agent'] is Map<String, dynamic> ? map['agent'] : {}),
      isFeatured: map['isFeatured'] ?? false,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? 0,
    );
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? purpose,
    String? propertyType,
    List<String>? images,
    String? videoUrl,
    PropertyLocation? location,
    double? area,
    String? areaUnit,
    int? bedrooms,
    int? bathrooms,
    List<String>? amenities,
    AgentModel? agent,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewsCount,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      purpose: purpose ?? this.purpose,
      propertyType: propertyType ?? this.propertyType,
      images: images ?? this.images,
      videoUrl: videoUrl ?? this.videoUrl,
      location: location ?? this.location,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      amenities: amenities ?? this.amenities,
      agent: agent ?? this.agent,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }

  /// Formatted Price string with Pakistani Lakh/Crore and International K/M support
  String get formattedPrice {
    if (currency == 'PKR' || currency == 'Rs') {
      if (price >= 10000000) {
        final croreVal = price / 10000000;
        return 'PKR ${croreVal.toStringAsFixed(croreVal.truncateToDouble() == croreVal ? 0 : 2)} Crore';
      } else if (price >= 100000) {
        final lakhVal = price / 100000;
        return 'PKR ${lakhVal.toStringAsFixed(lakhVal.truncateToDouble() == lakhVal ? 0 : 2)} Lac';
      } else {
        return 'PKR ${NumberFormat("#,##0").format(price)}';
      }
    } else {
      final formatter = NumberFormat.compactSimpleCurrency(name: currency == 'USD' ? '\$' : currency);
      return formatter.format(price);
    }
  }

  /// Formatted Area (e.g., "10 Marla", "1 Kanal", "2,400 Sq Ft")
  String get formattedArea {
    final formattedNumber = area.truncateToDouble() == area
        ? area.toInt().toString()
        : area.toStringAsFixed(1);
    return '$formattedNumber $areaUnit';
  }

  /// Cover Image fallback
  String get coverImage {
    if (images.isNotEmpty && images.first.isNotEmpty) {
      return images.first;
    }
    return 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80';
  }
}
