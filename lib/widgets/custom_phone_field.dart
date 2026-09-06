import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../models/country_code.dart';

class CustomPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final CountryCode? initialCountry;
  final ValueChanged<CountryCode>? onCountryChanged;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final bool isRequired;

  const CustomPhoneField({
    super.key,
    required this.controller,
    this.label = 'Phone Number',
    this.initialCountry = CountryCode.defaultCountry,
    this.onCountryChanged,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.enabled = true,
    this.isRequired = true,
  });

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  CountryCode _selectedCountry = CountryCode.defaultCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? CountryCode.defaultCountry;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant CustomPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openCountryPicker() {
    showModalBottomSheet<CountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          Navigator.pop(context, country);
        },
      ),
    ).then((selected) {
      if (selected != null && selected != _selectedCountry) {
        setState(() {
          _selectedCountry = selected;
          // Trim text if it exceeds the new country's limit
          if (widget.controller.text.length > selected.digitCount) {
            widget.controller.text =
                widget.controller.text.substring(0, selected.digitCount);
          }
        });
        widget.onCountryChanged?.call(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = widget.controller.text.length;
    final targetDigits = _selectedCountry.digitCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy,
              ),
            ),
            Text(
              '$currentLength / $targetDigits digits',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: currentLength == targetDigits
                    ? AppColors.success
                    : AppColors.slateBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.phone,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          inputFormatters: [
            _PhoneNumberFormatter(targetDigits),
          ],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.darkNavy,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            hintText: '${_selectedCountry.example} ($targetDigits digits)',
            hintStyle: const TextStyle(
              color: AppColors.silverGrey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: InkWell(
              onTap: widget.enabled ? _openCountryPicker : null,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountry.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedCountry.dialCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.slateBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      width: 1.2,
                      color: AppColors.borderGrey,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            suffixIcon: currentLength == targetDigits
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  )
                : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              if (!widget.isRequired) return null;
              return 'Please enter your phone number';
            }
            final digits = value.replaceAll(RegExp(r'\D'), '');
            if (digits.length != targetDigits) {
              return 'Must be $targetDigits digits for ${_selectedCountry.name} (${_selectedCountry.dialCode})';
            }
            if (widget.validator != null) {
              return widget.validator!(value);
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode> onSelect;

  const _CountryPickerSheet({
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryCode> _filtered = CountryCode.countries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = CountryCode.countries;
      } else {
        _filtered = CountryCode.countries.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.dialCode.toLowerCase().contains(query) ||
              c.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Country Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: AppColors.slateBlue,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search country or code (e.g. Pakistan, +92)...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.slateBlue,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.scaffoldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 16, color: AppColors.borderGrey),

          // Countries List
          Flexible(
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        'No country found',
                        style: TextStyle(
                          color: AppColors.slateBlue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 20,
                      color: AppColors.borderGrey,
                    ),
                    itemBuilder: (context, index) {
                      final country = _filtered[index];
                      final isSelected = country == widget.selectedCountry;

                      return ListTile(
                        onTap: () => widget.onSelect(country),
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        title: Text(
                          country.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.darkNavy,
                          ),
                        ),
                        subtitle: Text(
                          '${country.digitCount} digits • e.g. ${country.example}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slateBlue,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.scaffoldBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                country.dialCode,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.darkNavy,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  final int digitCount;

  _PhoneNumberFormatter(this.digitCount);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    // Strip leading zeroes automatically
    if (text.startsWith('0')) {
      text = text.replaceFirst(RegExp(r'^0+'), '');
    }
    // Only allow digits
    text = text.replaceAll(RegExp(r'\D'), '');
    // Limit to digitCount
    if (text.length > digitCount) {
      text = text.substring(0, digitCount);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
