import 'dart:async';
import 'package:flutter/material.dart';

enum ReaderTheme {
  light,
  dark,
  sepia,
  oled,
}

enum ReaderAlignment {
  left,
  center,
  justified,
}

class ReaderSettings {
  final ReaderTheme theme;
  final String typeface;
  final double textSize;
  final double autoScrollSpeed;
  final double lineHeight;
  final ReaderAlignment alignment;
  final bool usePublisherDefaults;

  const ReaderSettings({
    this.theme = ReaderTheme.light,
    this.typeface = 'Georgia',
    this.textSize = 18.0,
    this.autoScrollSpeed = 1.0,
    this.lineHeight = 1.6,
    this.alignment = ReaderAlignment.left,
    this.usePublisherDefaults = false,
  });

  ReaderSettings copyWith({
    ReaderTheme? theme,
    String? typeface,
    double? textSize,
    double? autoScrollSpeed,
    double? lineHeight,
    ReaderAlignment? alignment,
    bool? usePublisherDefaults,
  }) {
    return ReaderSettings(
      theme: theme ?? this.theme,
      typeface: typeface ?? this.typeface,
      textSize: textSize ?? this.textSize,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      lineHeight: lineHeight ?? this.lineHeight,
      alignment: alignment ?? this.alignment,
      usePublisherDefaults: usePublisherDefaults ?? this.usePublisherDefaults,
    );
  }

  static const availableTypefaces = [
    'System',
    'Georgia',
    'Merriweather',
    'Lora',
    'Roboto',
    'Open Sans'
  ];

  static const themePreviewColors = {
    ReaderTheme.light: Color(0xFFFDFDFD),
    ReaderTheme.dark: Color(0xFF1A1A1A),
    ReaderTheme.sepia: Color(0xFFF5EFE1),
    ReaderTheme.oled: Color(0xFF000000),
  };
}

class DisplaySettingsSheet extends StatefulWidget {
  final ReaderSettings currentSettings;
  final ValueChanged<ReaderSettings> onSettingsChanged;

  const DisplaySettingsSheet({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<DisplaySettingsSheet> createState() => _DisplaySettingsSheetState();
}

class _DisplaySettingsSheetState extends State<DisplaySettingsSheet> {
  late ReaderSettings _settings;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _updateSettings(ReaderSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      widget.onSettingsChanged(_settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom sheet background based on app theme (or current reader theme)
    final isDark = Theme.of(context).brightness == Brightness.dark ||
        _settings.theme == ReaderTheme.dark ||
        _settings.theme == ReaderTheme.oled;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final dividerColor = isDark ? Colors.white24 : Colors.black12;
    final accentColor = const Color(0xFFFF7A3B); // App accent

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Display Settings',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: secondaryTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Theme Section
            _buildSectionLabel('THEME', secondaryTextColor),
            const SizedBox(height: 12),
            _buildThemeSelector(accentColor, dividerColor),
            const SizedBox(height: 28),

            // Typeface Section
            _buildSectionLabel('TYPEFACE', secondaryTextColor),
            const SizedBox(height: 12),
            _buildTypefaceDropdown(bgColor, textColor, dividerColor),
            const SizedBox(height: 28),

            // Size & Layout Section
            _buildSectionLabel('SIZE & LAYOUT', secondaryTextColor),
            const SizedBox(height: 16),

            // Text Size Slider
            _buildSliderRow(
              label: 'Text Size',
              value: _settings.textSize,
              min: 12,
              max: 32,
              divisions: 20,
              displayValue: '${_settings.textSize.round()}px',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              accentColor: accentColor,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(textSize: value));
              },
            ),
            // Auto Scroll Speed Slider
            _buildSliderRow(
              label: 'Auto Scroll Speed',
              value: _settings.autoScrollSpeed,
              min: 0.5,
              max: 10.0,
              divisions: 19,
              displayValue: '${_settings.autoScrollSpeed.toStringAsFixed(1)}x',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              accentColor: accentColor,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(autoScrollSpeed: value));
              },
            ),
            const SizedBox(height: 16),

            // Line Height Slider
            _buildSliderRow(
              label: 'Line Height',
              value: _settings.lineHeight,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              displayValue: _settings.lineHeight.toStringAsFixed(1),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              accentColor: accentColor,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(lineHeight: value));
              },
            ),
            const SizedBox(height: 20),

            // Alignment Buttons
            _buildAlignmentSelector(textColor, accentColor, dividerColor),
            const SizedBox(height: 28),

            // Publisher Defaults Toggle
            _buildPublisherDefaultsToggle(textColor, accentColor, dividerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildThemeSelector(Color accentColor, Color dividerColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ReaderTheme.values.map((theme) {
        final isSelected = _settings.theme == theme;
        final color = ReaderSettings.themePreviewColors[theme]!;

        return GestureDetector(
          onTap: () => _updateSettings(_settings.copyWith(theme: theme)),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accentColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dividerColor,
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypefaceDropdown(
      Color bgColor, Color textColor, Color dividerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _settings.typeface,
          isExpanded: true,
          dropdownColor: bgColor,
          style: TextStyle(color: textColor, fontSize: 16),
          icon: Icon(Icons.keyboard_arrow_down,
              color: textColor.withOpacity(0.5)),
          items: ReaderSettings.availableTypefaces.map((typeface) {
            return DropdownMenuItem(
              value: typeface,
              child: Text(
                typeface,
                style: TextStyle(
                  fontFamily: typeface == 'System' ? null : typeface,
                  color: textColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _updateSettings(_settings.copyWith(typeface: value));
            }
          },
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color accentColor,
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: secondaryTextColor.withOpacity(0.2),
            thumbColor: accentColor,
            overlayColor: accentColor.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAlignmentSelector(
      Color textColor, Color accentColor, Color dividerColor) {
    return Row(
      children: [
        _buildAlignmentButton(
          icon: Icons.format_align_left,
          isSelected: _settings.alignment == ReaderAlignment.left,
          onTap: () => _updateSettings(
              _settings.copyWith(alignment: ReaderAlignment.left)),
          textColor: textColor,
          accentColor: accentColor,
          dividerColor: dividerColor,
        ),
        const SizedBox(width: 8),
        _buildAlignmentButton(
          icon: Icons.format_align_center,
          isSelected: _settings.alignment == ReaderAlignment.center,
          onTap: () => _updateSettings(
              _settings.copyWith(alignment: ReaderAlignment.center)),
          textColor: textColor,
          accentColor: accentColor,
          dividerColor: dividerColor,
        ),
        const SizedBox(width: 8),
        _buildAlignmentButton(
          icon: Icons.format_align_justify,
          isSelected: _settings.alignment == ReaderAlignment.justified,
          onTap: () => _updateSettings(
              _settings.copyWith(alignment: ReaderAlignment.justified)),
          textColor: textColor,
          accentColor: accentColor,
          dividerColor: dividerColor,
        ),
      ],
    );
  }

  Widget _buildAlignmentButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required Color accentColor,
    required Color dividerColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.1)
                : dividerColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : dividerColor,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? accentColor : textColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPublisherDefaultsToggle(
      Color textColor, Color accentColor, Color dividerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Publisher Defaults',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          Switch(
            value: _settings.usePublisherDefaults,
            onChanged: (value) => _updateSettings(
                _settings.copyWith(usePublisherDefaults: value)),
            activeColor: accentColor,
            activeTrackColor: accentColor.withOpacity(0.5),
            inactiveTrackColor: dividerColor,
          ),
        ],
      ),
    );
  }
}

void showDisplaySettingsSheet(
  BuildContext context, {
  required ReaderSettings currentSettings,
  required ValueChanged<ReaderSettings> onSettingsChanged,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DisplaySettingsSheet(
      currentSettings: currentSettings,
      onSettingsChanged: onSettingsChanged,
    ),
  );
}
