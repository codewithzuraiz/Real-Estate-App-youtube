class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int digitCount;
  final String example;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.digitCount,
    required this.example,
  });

  static const CountryCode defaultCountry = CountryCode(
    name: 'Pakistan',
    code: 'PK',
    dialCode: '+92',
    flag: '🇵🇰',
    digitCount: 10,
    example: '300 1234567',
  );

  static const List<CountryCode> countries = [
    CountryCode(
      name: 'Pakistan',
      code: 'PK',
      dialCode: '+92',
      flag: '🇵🇰',
      digitCount: 10,
      example: '300 1234567',
    ),
    CountryCode(
      name: 'United States',
      code: 'US',
      dialCode: '+1',
      flag: '🇺🇸',
      digitCount: 10,
      example: '202 555 0123',
    ),
    CountryCode(
      name: 'United Kingdom',
      code: 'GB',
      dialCode: '+44',
      flag: '🇬🇧',
      digitCount: 10,
      example: '7911 123456',
    ),
    CountryCode(
      name: 'United Arab Emirates',
      code: 'AE',
      dialCode: '+971',
      flag: '🇦🇪',
      digitCount: 9,
      example: '50 123 4567',
    ),
    CountryCode(
      name: 'Saudi Arabia',
      code: 'SA',
      dialCode: '+966',
      flag: '🇸🇦',
      digitCount: 9,
      example: '50 123 4567',
    ),
    CountryCode(
      name: 'India',
      code: 'IN',
      dialCode: '+91',
      flag: '🇮🇳',
      digitCount: 10,
      example: '98765 43210',
    ),
    CountryCode(
      name: 'Canada',
      code: 'CA',
      dialCode: '+1',
      flag: '🇨🇦',
      digitCount: 10,
      example: '416 555 0199',
    ),
    CountryCode(
      name: 'Australia',
      code: 'AU',
      dialCode: '+61',
      flag: '🇦🇺',
      digitCount: 9,
      example: '412 345 678',
    ),
    CountryCode(
      name: 'Qatar',
      code: 'QA',
      dialCode: '+974',
      flag: '🇶🇦',
      digitCount: 8,
      example: '3312 3456',
    ),
    CountryCode(
      name: 'Kuwait',
      code: 'KW',
      dialCode: '+965',
      flag: '🇰🇼',
      digitCount: 8,
      example: '9123 4567',
    ),
    CountryCode(
      name: 'Oman',
      code: 'OM',
      dialCode: '+968',
      flag: '🇴🇲',
      digitCount: 8,
      example: '9123 4567',
    ),
    CountryCode(
      name: 'Bahrain',
      code: 'BH',
      dialCode: '+973',
      flag: '🇧🇭',
      digitCount: 8,
      example: '3612 3456',
    ),
    CountryCode(
      name: 'Turkey',
      code: 'TR',
      dialCode: '+90',
      flag: '🇹🇷',
      digitCount: 10,
      example: '501 234 5678',
    ),
    CountryCode(
      name: 'Germany',
      code: 'DE',
      dialCode: '+49',
      flag: '🇩🇪',
      digitCount: 10,
      example: '151 23456789',
    ),
    CountryCode(
      name: 'France',
      code: 'FR',
      dialCode: '+33',
      flag: '🇫🇷',
      digitCount: 9,
      example: '6 12 34 56 78',
    ),
    CountryCode(
      name: 'Italy',
      code: 'IT',
      dialCode: '+39',
      flag: '🇮🇹',
      digitCount: 10,
      example: '312 345 6789',
    ),
    CountryCode(
      name: 'Spain',
      code: 'ES',
      dialCode: '+34',
      flag: '🇪🇸',
      digitCount: 9,
      example: '612 345 678',
    ),
    CountryCode(
      name: 'Malaysia',
      code: 'MY',
      dialCode: '+60',
      flag: '🇲🇾',
      digitCount: 10,
      example: '12 345 6789',
    ),
    CountryCode(
      name: 'Singapore',
      code: 'SG',
      dialCode: '+65',
      flag: '🇸🇬',
      digitCount: 8,
      example: '8123 4567',
    ),
    CountryCode(
      name: 'Bangladesh',
      code: 'BD',
      dialCode: '+880',
      flag: '🇧🇩',
      digitCount: 10,
      example: '1712 345678',
    ),
    CountryCode(
      name: 'Egypt',
      code: 'EG',
      dialCode: '+20',
      flag: '🇪🇬',
      digitCount: 10,
      example: '100 123 4567',
    ),
    CountryCode(
      name: 'South Africa',
      code: 'ZA',
      dialCode: '+27',
      flag: '🇿🇦',
      digitCount: 9,
      example: '71 234 5678',
    ),
    CountryCode(
      name: 'Indonesia',
      code: 'ID',
      dialCode: '+62',
      flag: '🇮🇩',
      digitCount: 10,
      example: '812 3456 7890',
    ),
    CountryCode(
      name: 'China',
      code: 'CN',
      dialCode: '+86',
      flag: '🇨🇳',
      digitCount: 11,
      example: '138 1234 5678',
    ),
    CountryCode(
      name: 'Japan',
      code: 'JP',
      dialCode: '+81',
      flag: '🇯🇵',
      digitCount: 10,
      example: '90 1234 5678',
    ),
  ];

  static CountryCode findByCodeOrDial(String query) {
    final clean = query.trim().replaceAll('+', '');
    for (final c in countries) {
      if (c.code.toLowerCase() == query.trim().toLowerCase() ||
          c.dialCode.replaceAll('+', '') == clean) {
        return c;
      }
    }
    return defaultCountry;
  }

  static ({CountryCode country, String localNumber}) parsePhone(String fullPhone) {
    final clean = fullPhone.trim();
    for (final c in countries) {
      if (clean.startsWith(c.dialCode)) {
        final local = clean.substring(c.dialCode.length).trim();
        return (country: c, localNumber: local);
      }
    }
    return (country: defaultCountry, localNumber: clean);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryCode &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          dialCode == other.dialCode;

  @override
  int get hashCode => code.hashCode ^ dialCode.hashCode;
}
