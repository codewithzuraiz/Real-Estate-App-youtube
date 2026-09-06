import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _propertiesCollection =>
      _firestore.collection('properties');

  CollectionReference<Map<String, dynamic>> _userFavoritesCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('favorites');

  /// Stream all properties or filtered properties
  Stream<List<PropertyModel>> streamProperties({
    String? purpose,
    String? propertyType,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    String? areaUnit,
  }) {
    Query<Map<String, dynamic>> query = _propertiesCollection.orderBy('createdAt', descending: true);

    if (purpose != null && purpose.isNotEmpty && purpose != 'All') {
      query = query.where('purpose', isEqualTo: purpose);
    }

    if (propertyType != null && propertyType.isNotEmpty && propertyType != 'All') {
      query = query.where('propertyType', isEqualTo: propertyType);
    }

    return query.snapshots().map((snapshot) {
      var properties = snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
          .toList();

      // Client-side filtering for complex search parameters
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.trim().toLowerCase();
        properties = properties.where((p) {
          final titleMatch = p.title.toLowerCase().contains(queryLower);
          final cityMatch = p.location.city.toLowerCase().contains(queryLower);
          final areaNameMatch = p.location.areaName.toLowerCase().contains(queryLower);
          final addressMatch = p.location.address.toLowerCase().contains(queryLower);
          final descMatch = p.description.toLowerCase().contains(queryLower);
          return titleMatch || cityMatch || areaNameMatch || addressMatch || descMatch;
        }).toList();
      }

      if (minPrice != null && minPrice > 0) {
        properties = properties.where((p) => p.price >= minPrice).toList();
      }

      if (maxPrice != null && maxPrice > 0) {
        properties = properties.where((p) => p.price <= maxPrice).toList();
      }

      if (minBedrooms != null && minBedrooms > 0) {
        properties = properties.where((p) => p.bedrooms >= minBedrooms).toList();
      }

      if (areaUnit != null && areaUnit.isNotEmpty && areaUnit != 'All') {
        properties = properties.where((p) => p.areaUnit.toLowerCase() == areaUnit.toLowerCase()).toList();
      }

      return properties;
    });
  }

  /// Stream featured properties
  Stream<List<PropertyModel>> streamFeaturedProperties() {
    return _propertiesCollection
        .where('isFeatured', isEqualTo: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream single property details
  Stream<PropertyModel?> streamPropertyById(String propertyId) {
    return _propertiesCollection.doc(propertyId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PropertyModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Get single property directly
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    final doc = await _propertiesCollection.doc(propertyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PropertyModel.fromMap(doc.data()!, doc.id);
  }

  /// Add new property listing
  Future<String> addProperty(PropertyModel property) async {
    final data = property.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _propertiesCollection.add(data);
    return docRef.id;
  }

  /// Update existing property listing
  Future<void> updateProperty(PropertyModel property) async {
    final data = property.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _propertiesCollection.doc(property.id).update(data);
  }

  /// Stream properties listed by a specific seller
  Stream<List<PropertyModel>> streamSellerProperties(String sellerId) {
    return _propertiesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
          .where((p) => p.sellerId == sellerId || p.agent.id == sellerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Update property status ('Active' vs 'Sold')
  Future<void> updatePropertyStatus(String propertyId, String status) async {
    await _propertiesCollection.doc(propertyId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete property
  Future<void> deleteProperty(String propertyId) async {
    await _propertiesCollection.doc(propertyId).delete();
  }

  /// Increment views count
  Future<void> incrementViews(String propertyId) async {
    await _propertiesCollection.doc(propertyId).update({
      'viewsCount': FieldValue.increment(1),
    }).catchError((_) {});
  }

  /// Stream list of favorite property IDs for a user
  Stream<Set<String>> streamFavoriteIds(String userId) {
    return _userFavoritesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  /// Stream favorite properties for a user
  Stream<List<PropertyModel>> streamFavoriteProperties(String userId) {
    return _userFavoritesCollection(userId).snapshots().asyncMap((favSnapshot) async {
      if (favSnapshot.docs.isEmpty) return <PropertyModel>[];

      final propertyIds = favSnapshot.docs.map((d) => d.id).toList();
      final properties = <PropertyModel>[];

      // Fetch properties in batches of 10 for Firestore 'whereIn' limits
      for (var i = 0; i < propertyIds.length; i += 10) {
        final batchIds = propertyIds.sublist(
          i,
          (i + 10 > propertyIds.length) ? propertyIds.length : i + 10,
        );
        final propSnapshot = await _propertiesCollection
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final doc in propSnapshot.docs) {
          properties.add(PropertyModel.fromMap(doc.data(), doc.id));
        }
      }

      return properties;
    });
  }

  /// Toggle property favorite status
  Future<bool> toggleFavorite(String userId, String propertyId) async {
    final docRef = _userFavoritesCollection(userId).doc(propertyId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      return false; // removed
    } else {
      await docRef.set({
        'propertyId': propertyId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      return true; // added
    }
  }

  /// Seed high quality realistic sample property listings
  Future<void> seedSampleProperties() async {
    for (final prop in sampleProperties) {
      await addProperty(prop);
    }
  }

  static List<PropertyModel> get sampleProperties => [
      PropertyModel(
        id: '',
        title: 'Luxury 1 Kanal Modern Designer Villa',
        description:
            'A state-of-the-art 1 Kanal ultra-modern masterpiece located in the prime sector of DHA Phase 6. Featuring imported Italian marble flooring, double-height ceiling lobby, smart home automation, private swimming pool, landscaped lawn, dedicated home theater, and dirty kitchen.\n\nIdeal for executive living with 24/7 high-security gated community.',
        price: 98000000, // 9.8 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'House / Villa',
        images: [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        location: const PropertyLocation(
          address: 'Sector K, Phase 6',
          areaName: 'DHA Defence',
          city: 'Lahore',
          latitude: 31.4720,
          longitude: 74.4312,
        ),
        area: 1.0,
        areaUnit: 'Kanal',
        bedrooms: 5,
        bathrooms: 6,
        amenities: [
          'Swimming Pool',
          '24/7 Security & CCTV',
          'Covered Car Parking',
          'Lawn / Landscaped Garden',
          'Smart Home Automation',
          'Central Air Conditioning',
          'Solar Power Backup',
          'High Speed Internet',
          'Servant Quarter',
        ],
        agent: const AgentModel(
          id: 'agent_1',
          name: 'Hamza Malik',
          agency: 'DHA Prestige Estates',
          phone: '+92 300 8472910',
          email: 'hamza.malik@prestigeestates.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.9,
          reviewsCount: 38,
        ),
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        viewsCount: 142,
      ),
      PropertyModel(
        id: '',
        title: 'Executive 3-Bed Luxury Skyline Penthouse',
        description:
            'Experience panoramic skyline views in this high-floor 3-bedroom luxury penthouse in Gulberg III. Designed with floor-to-ceiling soundproof glass, open-concept German kitchen with integrated Bosch appliances, private elevator access, wrap-around sunset balcony, and access to an infinity rooftop pool & world-class gymnasium.',
        price: 45000000, // 4.5 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'Penthouse',
        images: [
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        location: const PropertyLocation(
          address: 'Main Boulevard, Gulberg III',
          areaName: 'Gulberg',
          city: 'Lahore',
          latitude: 31.5168,
          longitude: 74.3436,
        ),
        area: 2850,
        areaUnit: 'Sq Ft',
        bedrooms: 3,
        bathrooms: 4,
        amenities: [
          'High-Speed Private Elevator',
          'Rooftop Infinity Pool',
          'Gym & Fitness Club',
          'Covered Basement Parking',
          '24/7 Security & CCTV',
          'Central AC & Heating',
          'Standby Generator',
          'Balcony with Skyline View',
        ],
        agent: const AgentModel(
          id: 'agent_2',
          name: 'Ayesha Siddiqui',
          agency: 'Apex Capital Properties',
          phone: '+92 321 4458921',
          email: 'ayesha.s@apexproperties.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.8,
          reviewsCount: 29,
        ),
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        viewsCount: 215,
      ),
      PropertyModel(
        id: '',
        title: 'Brand New 10 Marla Spanish Villa',
        description:
            'Stunning 10 Marla double-storey Spanish design house for sale in Bahria Town. Built with solid Ash wood work, Turkish sanitary fittings, 2 modern kitchens, false ceiling with ambient LED lighting, and a spacious car porch for 2 SUVs.',
        price: 36500000, // 3.65 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'House / Villa',
        images: [
          'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Sector C, Jasmine Block',
          areaName: 'Bahria Town',
          city: 'Lahore',
          latitude: 31.3686,
          longitude: 74.1842,
        ),
        area: 10.0,
        areaUnit: 'Marla',
        bedrooms: 4,
        bathrooms: 5,
        amenities: [
          'Dedicated 2-Car Porch',
          'Dual Modern Kitchens',
          '24/7 Gated Security',
          'Balcony',
          'Nearby Grand Mosque & Park',
          'Solar Inverter Ready',
        ],
        agent: const AgentModel(
          id: 'agent_3',
          name: 'Usman Tariq',
          agency: 'Bahria Premier Realtors',
          phone: '+92 333 9988112',
          email: 'usman.tariq@premierreal.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.7,
          reviewsCount: 19,
        ),
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        viewsCount: 88,
      ),
      PropertyModel(
        id: '',
        title: 'Furnished 2-Bed Luxury Apartment for Rent',
        description:
            'Fully furnished modern 2-bedroom apartment available for immediate rent in F-11 Islamabad. Fully equipped with LED TVs, inverter ACs in all rooms, refrigerator, microwave, designer furniture, and high-speed Wi-Fi included. Dedicated underground parking spot and 24/7 security.',
        price: 160000, // 160,000 / month
        currency: 'PKR',
        purpose: 'For Rent',
        propertyType: 'Apartment',
        images: [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1502005229762-ee1b2b93e000?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Markaz F-11/2',
          areaName: 'Sector F-11',
          city: 'Islamabad',
          latitude: 33.6844,
          longitude: 73.0479,
        ),
        area: 1450,
        areaUnit: 'Sq Ft',
        bedrooms: 2,
        bathrooms: 2,
        amenities: [
          'Fully Furnished',
          'Dedicated Basement Parking',
          'High Speed Wi-Fi',
          'Elevator Access',
          '24/7 Security Guard',
          'Inverter Air Conditioners',
          'Backup Generator',
        ],
        agent: const AgentModel(
          id: 'agent_4',
          name: 'Zainab Shah',
          agency: 'Capital Gateway Housing',
          phone: '+92 312 7766554',
          email: 'zainab@capitalgateway.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.9,
          reviewsCount: 42,
        ),
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        viewsCount: 175,
      ),
      PropertyModel(
        id: '',
        title: '5 Marla Commercial Corner Plaza',
        description:
            'High-ROI 5 Marla commercial corner plot & building in prime commercial zone of Bahria Town. 4 floors including basement, ground, 1st and 2nd floor with already active corporate tenants generating steady monthly rental return.',
        price: 62000000, // 6.2 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'Commercial',
        images: [
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Commercial Broadway, Civic Centre',
          areaName: 'Bahria Enclave',
          city: 'Islamabad',
          latitude: 33.7294,
          longitude: 73.0931,
        ),
        area: 5.0,
        areaUnit: 'Marla',
        bedrooms: 0,
        bathrooms: 4,
        amenities: [
          'Main Corner Facing',
          'Front & Side Parking',
          'Passenger Elevator',
          'Emergency Fire System',
          'High Rental Yield',
          '3-Phase Commercial Meter',
        ],
        agent: const AgentModel(
          id: 'agent_1',
          name: 'Hamza Malik',
          agency: 'DHA Prestige Estates',
          phone: '+92 300 8472910',
          email: 'hamza.malik@prestigeestates.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.9,
          reviewsCount: 38,
        ),
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        viewsCount: 310,
      ),
      PropertyModel(
        id: '',
        title: '2 Kanal Luxury Farmhouse with Organic Orchard',
        description:
            'Peaceful 2 Kanal country retreat farmhouse on Bedian Road. Features open garden lawns, organic fruit trees, swimming pool, open barbecue deck, rustic gazebo, and 4 master bedrooms with ensuite bathrooms.',
        price: 75000000, // 7.5 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'Farmhouse',
        images: [
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Main Bedian Road, Near DHA Phase 9 Prism',
          areaName: 'Bedian Road',
          city: 'Lahore',
          latitude: 31.4200,
          longitude: 74.4800,
        ),
        area: 2.0,
        areaUnit: 'Kanal',
        bedrooms: 4,
        bathrooms: 5,
        amenities: [
          'Private Swimming Pool',
          'Barbecue & Grill Deck',
          'Lush Green Lawn & Orchard',
          '24/7 Security Boundary',
          'Tube Well & Deep Water Boring',
          'Spacious Gazebo',
        ],
        agent: const AgentModel(
          id: 'agent_2',
          name: 'Ayesha Siddiqui',
          agency: 'Apex Capital Properties',
          phone: '+92 321 4458921',
          email: 'ayesha.s@apexproperties.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.8,
          reviewsCount: 29,
        ),
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        viewsCount: 95,
      ),
      // Malir, Karachi Properties for Comparison
      PropertyModel(
        id: '',
        title: 'Luxury 240 Sq Yd Designer House in Malir Cantt',
        description:
            'Brand new 240 Sq Yd corner bungalow located in secure gated Malir Cantt. Featuring imported tile work, modern American kitchen, open rooftop terrace, servant quarter, and 2-car covered garage.',
        price: 38000000, // 3.8 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'House / Villa',
        images: [
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Falcon Complex, Sector C',
          areaName: 'Malir Cantt',
          city: 'Karachi',
          latitude: 24.9180,
          longitude: 67.1950,
        ),
        area: 240,
        areaUnit: 'Sq Yd',
        bedrooms: 4,
        bathrooms: 5,
        amenities: [
          '24/7 Security & CCTV',
          'Covered Car Parking',
          'Standby Generator',
          'Lawn / Landscaped Garden',
          'Servant Quarter',
          'Solar Power Backup',
        ],
        agent: const AgentModel(
          id: 'agent_5',
          name: 'Kamran Raza',
          agency: 'Karachi Cantt Realtors',
          phone: '+92 321 8234567',
          email: 'kamran.raza@canttrealtors.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.8,
          reviewsCount: 31,
        ),
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        viewsCount: 165,
      ),
      PropertyModel(
        id: '',
        title: 'Modern 120 Sq Yd Double Storey Villa in Malir',
        description:
            'Well-constructed 120 Sq Yd west-open double storey house in Model Colony Malir. Ideal for nuclear family with 3 bedrooms, 2 kitchens, marble floors, and secure water boring connection.',
        price: 21500000, // 2.15 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'House / Villa',
        images: [
          'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Block 4, Model Colony',
          areaName: 'Malir',
          city: 'Karachi',
          latitude: 24.8950,
          longitude: 67.1850,
        ),
        area: 120,
        areaUnit: 'Sq Yd',
        bedrooms: 3,
        bathrooms: 3,
        amenities: [
          'Covered Car Parking',
          'Balcony',
          '24/7 Security & CCTV',
          'Solar Inverter Ready',
        ],
        agent: const AgentModel(
          id: 'agent_5',
          name: 'Kamran Raza',
          agency: 'Karachi Cantt Realtors',
          phone: '+92 321 8234567',
          email: 'kamran.raza@canttrealtors.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.8,
          reviewsCount: 31,
        ),
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        viewsCount: 110,
      ),
      PropertyModel(
        id: '',
        title: 'Prime 500 Sq Yd Executive Bungalow in Malir Cantt',
        description:
            'Grand 500 Sq Yd royal mansion in Askari / Malir Cantt. Comprises 6 expansive master bedrooms, heated private swimming pool, basement media lounge, solar system with net metering, and 4-car porch.',
        price: 72000000, // 7.2 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'House / Villa',
        images: [
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Askari V, DOHS',
          areaName: 'Malir Cantt',
          city: 'Karachi',
          latitude: 24.9220,
          longitude: 67.2010,
        ),
        area: 500,
        areaUnit: 'Sq Yd',
        bedrooms: 6,
        bathrooms: 7,
        amenities: [
          'Swimming Pool',
          '24/7 Security & CCTV',
          'Solar Power Backup',
          'Central Air Conditioning',
          'Covered Car Parking',
          'Lawn / Landscaped Garden',
          'Servant Quarter',
          'Gym & Fitness Club',
        ],
        agent: const AgentModel(
          id: 'agent_5',
          name: 'Kamran Raza',
          agency: 'Karachi Cantt Realtors',
          phone: '+92 321 8234567',
          email: 'kamran.raza@canttrealtors.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.8,
          reviewsCount: 31,
        ),
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        viewsCount: 280,
      ),
      PropertyModel(
        id: '',
        title: 'Spacious 3-Bed Luxury Apartment in Malir Town',
        description:
            'Contemporary 1650 Sq Ft 3-bedroom corner flat in prime residential tower in Malir. Features high-speed elevators, standby backup generator, dedicated basement reserved parking, and park facing balcony.',
        price: 16500000, // 1.65 Crore
        currency: 'PKR',
        purpose: 'For Sale',
        propertyType: 'Apartment',
        images: [
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80',
        ],
        videoUrl: null,
        location: const PropertyLocation(
          address: 'Main Kala Board, Near RCD Ground',
          areaName: 'Malir',
          city: 'Karachi',
          latitude: 24.8870,
          longitude: 67.1780,
        ),
        area: 1650,
        areaUnit: 'Sq Ft',
        bedrooms: 3,
        bathrooms: 3,
        amenities: [
          'Passenger Elevator',
          '24/7 Security & CCTV',
          'Standby Generator',
          'Balcony with Skyline View',
          'Covered Basement Parking',
        ],
        agent: const AgentModel(
          id: 'agent_5',
          name: 'Kamran Raza',
          agency: 'Karachi Cantt Realtors',
          phone: '+92 321 8234567',
          email: 'kamran.raza@canttrealtors.pk',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
          isVerified: true,
          rating: 4.8,
          reviewsCount: 31,
        ),
        isFeatured: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        viewsCount: 140,
      ),
    ];
}

