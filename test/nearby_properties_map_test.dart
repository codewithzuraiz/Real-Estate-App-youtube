import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:real_estate_app/services/property_service.dart';

void main() {
  group('Nearby Properties Map Tests', () {
    test('Calculates distance in kilometers accurately', () {
      const lahoreCenter = LatLng(31.5204, 74.3587);
      const dhaPhase6 = LatLng(31.4720, 74.4312);

      const distanceCalculator = Distance();
      final distanceKm = distanceCalculator.as(
        LengthUnit.Kilometer,
        lahoreCenter,
        dhaPhase6,
      );

      expect(distanceKm, greaterThan(8.0));
      expect(distanceKm, lessThan(12.0));
    });

    test('All sample properties have valid coordinates and non-empty titles', () {
      final properties = PropertyService.sampleProperties;
      expect(properties.isNotEmpty, isTrue);

      for (final p in properties) {
        expect(p.location.latitude, isNot(0.0));
        expect(p.location.longitude, isNot(0.0));
        expect(p.title.isNotEmpty, isTrue);
        expect(p.price, greaterThan(0));
      }
    });

    test('Filter properties by radius correctly excludes far away properties', () {
      const lahoreCenter = LatLng(31.5204, 74.3587);
      const distanceCalculator = Distance();

      final properties = PropertyService.sampleProperties;

      // Filter within 15 km of Lahore Center
      final within15Km = properties.where((p) {
        final dist = distanceCalculator.as(
          LengthUnit.Kilometer,
          lahoreCenter,
          LatLng(p.location.latitude, p.location.longitude),
        );
        return dist <= 15.0;
      }).toList();

      // Properties in Islamabad or Karachi should NOT be within 15 km of Lahore
      for (final p in within15Km) {
        expect(p.location.city, 'Lahore');
      }
    });

    test('Short price formatting logic produces clean compact map badges', () {
      String formatShort(double price, String purpose) {
        String short;
        if (price >= 10000000) {
          final cr = price / 10000000;
          short = '${cr.toStringAsFixed(cr % 1 == 0 ? 0 : 1)} Cr';
        } else if (price >= 100000) {
          final lac = price / 100000;
          short = '${lac.toStringAsFixed(lac % 1 == 0 ? 0 : 1)} Lac';
        } else if (price >= 1000) {
          short = '${(price / 1000).round()}k';
        } else {
          short = price.toStringAsFixed(0);
        }

        if (purpose.toLowerCase().contains('rent')) {
          return '₨ $short/mo';
        }
        return '₨ $short';
      }

      expect(formatShort(98000000, 'For Sale'), '₨ 9.8 Cr');
      expect(formatShort(45000000, 'For Sale'), '₨ 4.5 Cr');
      expect(formatShort(125000, 'For Rent'), '₨ 1.3 Lac/mo');
      expect(formatShort(250000, 'For Rent'), '₨ 2.5 Lac/mo');
    });

    test('Distance from user location maintains true distance when property is selected', () {
      const userLocation = LatLng(31.5204, 74.3587); // Lahore Center
      const dhaPhase6 = LatLng(31.4720, 74.4312); // Property location
      const distanceCalculator = Distance();

      final distanceKm = distanceCalculator.as(
        LengthUnit.Kilometer,
        userLocation,
        dhaPhase6,
      );

      String formatDistance(double km) {
        if (km < 0.05) return '< 50 m';
        if (km < 1.0) return '${(km * 1000).round()} m';
        return '${km.toStringAsFixed(1)} km';
      }

      // Distance should NOT be 0 m away
      expect(distanceKm, greaterThan(8.0));
      expect(formatDistance(distanceKm), contains('km'));
      expect(formatDistance(0.02), '< 50 m');
      expect(formatDistance(0.4), '400 m');
    });
  });
}
