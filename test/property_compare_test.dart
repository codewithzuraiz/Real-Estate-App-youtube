import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/models/property_model.dart';
import 'package:real_estate_app/services/property_compare_service.dart';
import 'package:real_estate_app/widgets/compare_bottom_bar.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('PropertyCompareService Tests', () {
    late PropertyCompareService compareService;

    final dummyProp1 = PropertyModel(
      id: 'p1',
      title: '240 Sq Yd House in Malir Cantt',
      description: 'Test desc 1',
      price: 38000000,
      propertyType: 'House / Villa',
      location: const PropertyLocation(
        address: 'Sector C',
        areaName: 'Malir Cantt',
        city: 'Karachi',
      ),
      area: 240,
      areaUnit: 'Sq Yd',
      bedrooms: 4,
      bathrooms: 5,
      amenities: ['24/7 Security', 'Covered Parking'],
      agent: const AgentModel(
        id: 'a1',
        name: 'Kamran Raza',
        phone: '+923218234567',
        email: 'kamran@test.pk',
      ),
      createdAt: DateTime.now(),
    );

    final dummyProp2 = PropertyModel(
      id: 'p2',
      title: '120 Sq Yd Villa in Malir',
      description: 'Test desc 2',
      price: 21500000,
      propertyType: 'House / Villa',
      location: const PropertyLocation(
        address: 'Model Colony',
        areaName: 'Malir',
        city: 'Karachi',
      ),
      area: 120,
      areaUnit: 'Sq Yd',
      bedrooms: 3,
      bathrooms: 3,
      amenities: ['Covered Parking', 'Balcony'],
      agent: const AgentModel(
        id: 'a1',
        name: 'Kamran Raza',
        phone: '+923218234567',
        email: 'kamran@test.pk',
      ),
      createdAt: DateTime.now(),
    );

    final dummyProp3 = PropertyModel(
      id: 'p3',
      title: '500 Sq Yd Bungalow in Malir Cantt',
      description: 'Test desc 3',
      price: 72000000,
      propertyType: 'House / Villa',
      location: const PropertyLocation(
        address: 'Askari V',
        areaName: 'Malir Cantt',
        city: 'Karachi',
      ),
      area: 500,
      areaUnit: 'Sq Yd',
      bedrooms: 6,
      bathrooms: 7,
      amenities: ['Swimming Pool', '24/7 Security', 'Solar Backup'],
      agent: const AgentModel(
        id: 'a1',
        name: 'Kamran Raza',
        phone: '+923218234567',
        email: 'kamran@test.pk',
      ),
      createdAt: DateTime.now(),
    );

    final dummyProp4 = PropertyModel(
      id: 'p4',
      title: 'Luxury Apartment in Malir Town',
      description: 'Test desc 4',
      price: 16500000,
      propertyType: 'Apartment',
      location: const PropertyLocation(
        address: 'Kala Board',
        areaName: 'Malir',
        city: 'Karachi',
      ),
      area: 1650,
      areaUnit: 'Sq Ft',
      bedrooms: 3,
      bathrooms: 3,
      amenities: ['Elevator', '24/7 Security'],
      agent: const AgentModel(
        id: 'a1',
        name: 'Kamran Raza',
        phone: '+923218234567',
        email: 'kamran@test.pk',
      ),
      createdAt: DateTime.now(),
    );

    final dummyProp5 = PropertyModel(
      id: 'p5',
      title: 'Extra Property 5',
      description: 'Test desc 5',
      price: 50000000,
      propertyType: 'Plot',
      location: const PropertyLocation(
        address: 'Phase 2',
        areaName: 'Malir',
        city: 'Karachi',
      ),
      area: 10,
      areaUnit: 'Marla',
      bedrooms: 0,
      bathrooms: 0,
      agent: const AgentModel(
        id: 'a1',
        name: 'Kamran Raza',
        phone: '+923218234567',
        email: 'kamran@test.pk',
      ),
      createdAt: DateTime.now(),
    );

    setUp(() {
      compareService = PropertyCompareService();
      compareService.clear();
    });

    tearDown(() {
      compareService.clear();
    });

    test('Add, toggle and limit at 4 properties', () {
      expect(compareService.isEmpty, isTrue);

      // Add 3 properties (Malir comparison scenario)
      expect(compareService.add(dummyProp1), isTrue);
      expect(compareService.add(dummyProp2), isTrue);
      expect(compareService.add(dummyProp3), isTrue);
      expect(compareService.count, 3);
      expect(compareService.isInCompare('p1'), isTrue);
      expect(compareService.isInCompare('p2'), isTrue);
      expect(compareService.isInCompare('p3'), isTrue);

      // Add 4th property
      expect(compareService.add(dummyProp4), isTrue);
      expect(compareService.isFull, isTrue);

      // 5th property should be rejected due to 4 property max limit
      expect(compareService.add(dummyProp5), isFalse);
      expect(compareService.count, 4);

      // Toggle off property 2
      final removed = compareService.toggle(dummyProp2);
      expect(removed, isFalse);
      expect(compareService.isInCompare('p2'), isFalse);
      expect(compareService.count, 3);

      // Toggle back on property 2
      final added = compareService.toggle(dummyProp2);
      expect(added, isTrue);
      expect(compareService.isInCompare('p2'), isTrue);
      expect(compareService.count, 4);
    });

    test('Area unit normalization to Sq Ft calculations', () {
      // 10 Marla = 2,250 Sq Ft
      expect(PropertyCompareService.normalizeToSqFt(10, 'Marla'), 2250.0);

      // 1 Kanal = 4,500 Sq Ft
      expect(PropertyCompareService.normalizeToSqFt(1, 'Kanal'), 4500.0);

      // 240 Sq Yd = 2,160 Sq Ft
      expect(PropertyCompareService.normalizeToSqFt(240, 'Sq Yd'), 2160.0);

      // 1650 Sq Ft = 1,650 Sq Ft
      expect(PropertyCompareService.normalizeToSqFt(1650, 'Sq Ft'), 1650.0);
    });

    test('Price per Sq Ft calculation and winning badges', () {
      compareService.add(dummyProp1); // 38,000,000 / 2160 = ~17592.59
      compareService.add(dummyProp2); // 21,500,000 / 1080 = ~19907.40
      compareService.add(dummyProp3); // 72,000,000 / 4500 = 16000.00
      compareService.add(dummyProp4); // 16,500,000 / 1650 = 10000.00

      // Best (lowest) price is dummyProp4 (16.5 Million)
      expect(compareService.getBestPriceId(), 'p4');

      // Largest Area is dummyProp3 (500 Sq Yd = 4,500 Sq Ft)
      expect(compareService.getLargestAreaId(), 'p3');

      // Most Bedrooms is dummyProp3 (6 Bedrooms)
      expect(compareService.getMostBedroomsId(), 'p3');
    });

    testWidgets('CompareBottomBar renders when properties are in comparison', (tester) async {
      compareService.clear();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                CompareBottomBar(bottomPadding: 10),
              ],
            ),
          ),
        ),
      );

      // When empty, bar should not be visible
      expect(find.text('Compare'), findsNothing);

      // Add property and rebuild
      compareService.add(dummyProp1);
      await tester.pump();

      // Should now display Compare bar with 1/4 count
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('Add 1 more to compare'), findsOneWidget);

      // Add 2nd property
      compareService.add(dummyProp2);
      await tester.pump();

      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('2 properties ready'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  static final Uint8List _pngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _pngBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_pngBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {}
