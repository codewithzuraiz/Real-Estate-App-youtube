import 'package:flutter/foundation.dart';
import '../models/property_model.dart';

class PropertyCompareService extends ChangeNotifier {
  static final PropertyCompareService _instance = PropertyCompareService._internal();
  factory PropertyCompareService() => _instance;
  PropertyCompareService._internal();

  static const int maxProperties = 4;
  final List<PropertyModel> _properties = [];

  List<PropertyModel> get properties => List.unmodifiable(_properties);
  int get count => _properties.length;
  bool get isEmpty => _properties.isEmpty;
  bool get isNotEmpty => _properties.isNotEmpty;
  bool get isFull => _properties.length >= maxProperties;

  bool isInCompare(String id) {
    if (id.isEmpty) return false;
    return _properties.any((p) => p.id == id);
  }

  /// Adds a property if not already present and limit is not exceeded.
  /// Returns true if added, false if already in list or list is full.
  bool add(PropertyModel property) {
    if (isInCompare(property.id)) return false;
    if (_properties.length >= maxProperties) return false;
    _properties.add(property);
    notifyListeners();
    return true;
  }

  /// Removes a property by ID.
  void remove(String propertyId) {
    final initialLength = _properties.length;
    _properties.removeWhere((p) => p.id == propertyId);
    if (_properties.length != initialLength) {
      notifyListeners();
    }
  }

  /// Toggles property comparison status.
  /// Returns:
  /// - `true` if added
  /// - `false` if removed or list was full
  bool toggle(PropertyModel property) {
    if (isInCompare(property.id)) {
      remove(property.id);
      return false;
    } else {
      if (_properties.length >= maxProperties) {
        return false;
      }
      _properties.add(property);
      notifyListeners();
      return true;
    }
  }

  /// Clears all properties from comparison.
  void clear() {
    if (_properties.isNotEmpty) {
      _properties.clear();
      notifyListeners();
    }
  }

  /// Normalizes any area unit (Marla, Kanal, Sq Yd, Sq M) to standard Square Feet (Sq Ft)
  static double normalizeToSqFt(double area, String unit) {
    final lower = unit.trim().toLowerCase();
    if (lower.contains('marla')) {
      return area * 225.0; // 225 sq ft standard societal measurement
    } else if (lower.contains('kanal')) {
      return area * 4500.0; // 20 Marla = 4,500 sq ft
    } else if (lower.contains('yd') || lower.contains('yard')) {
      return area * 9.0; // 1 Sq Yd = 9 sq ft
    } else if (lower.contains('m') || lower.contains('meter')) {
      return area * 10.7639; // 1 Sq M = 10.7639 sq ft
    }
    return area; // already Sq Ft or fallback
  }

  /// Calculates price per square foot
  static double calculatePricePerSqFt(PropertyModel property) {
    final sqFt = normalizeToSqFt(property.area, property.areaUnit);
    if (sqFt <= 0) return 0.0;
    return property.price / sqFt;
  }

  /// Formats square feet nicely (e.g. 2,250 Sq Ft)
  static String formatSqFt(double sqFt) {
    final rounded = sqFt.round();
    final str = rounded.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formatted Sq Ft';
  }

  /// Formats price per square foot nicely (e.g. PKR 18,200 / Sq Ft)
  static String formatPricePerSqFt(double pricePerSqFt, {String currency = 'PKR'}) {
    final rounded = pricePerSqFt.round();
    final str = rounded.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$currency $formatted / Sq Ft';
  }

  /// Returns the ID of the property with the best / lowest price
  String? getBestPriceId() {
    if (_properties.length < 2) return null;
    PropertyModel lowest = _properties.first;
    for (final p in _properties) {
      if (p.price < lowest.price) {
        lowest = p;
      }
    }
    return lowest.id;
  }

  /// Returns the ID of the property with the largest area (in normalized Sq Ft)
  String? getLargestAreaId() {
    if (_properties.length < 2) return null;
    PropertyModel largest = _properties.first;
    double maxSqFt = normalizeToSqFt(largest.area, largest.areaUnit);
    for (final p in _properties) {
      final sqFt = normalizeToSqFt(p.area, p.areaUnit);
      if (sqFt > maxSqFt) {
        maxSqFt = sqFt;
        largest = p;
      }
    }
    return largest.id;
  }

  /// Returns the ID of the property with the most bedrooms
  String? getMostBedroomsId() {
    if (_properties.length < 2) return null;
    PropertyModel most = _properties.first;
    for (final p in _properties) {
      if (p.bedrooms > most.bedrooms) {
        most = p;
      }
    }
    if (most.bedrooms == 0) return null;
    return most.id;
  }
}
