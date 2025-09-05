import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({Key? key}) : super(key: key);

  @override
  State<ThemeCustomizationScreen> createState() => _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Customization'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Theme Mode'),
                _buildThemeModeSection(themeProvider),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Color Scheme'),
                _buildColorSchemeSection(themeProvider),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Custom Colors'),
                _buildCustomColorsSection(themeProvider),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Preview'),
                _buildPreviewSection(themeProvider),
                const SizedBox(height: 24),
                
                _buildSectionHeader('Accessibility'),
                _buildAccessibilitySection(themeProvider),
                const SizedBox(height: 24),
                
                _buildActionButtons(themeProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildThemeModeSection(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildThemeModeOption(
              'Light Mode',
              'Clean and bright interface',
              Icons.light_mode,
              ThemeMode.light,
              themeProvider.themeMode,
              (mode) => themeProvider.setThemeMode(mode),
            ),
            const Divider(),
            _buildThemeModeOption(
              'Dark Mode',
              'Easy on the eyes in low light',
              Icons.dark_mode,
              ThemeMode.dark,
              themeProvider.themeMode,
              (mode) => themeProvider.setThemeMode(mode),
            ),
            const Divider(),
            _buildThemeModeOption(
              'System Default',
              'Follows device settings',
              Icons.settings_system_daydream,
              ThemeMode.system,
              themeProvider.themeMode,
              (mode) => themeProvider.setThemeMode(mode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(
    String title,
    String description,
    IconData icon,
    ThemeMode mode,
    ThemeMode currentMode,
    Function(ThemeMode) onTap,
  ) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () => onTap(mode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSchemeSection(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildColorSchemeOption(
              'Default Blue',
              'Professional and trustworthy',
              const Color(0xFF2196F3),
              'default',
              themeProvider.colorScheme,
              (scheme) => themeProvider.setColorScheme(scheme),
            ),
            const Divider(),
            _buildColorSchemeOption(
              'Green Nature',
              'Calm and refreshing',
              const Color(0xFF4CAF50),
              'green',
              themeProvider.colorScheme,
              (scheme) => themeProvider.setColorScheme(scheme),
            ),
            const Divider(),
            _buildColorSchemeOption(
              'Purple Royal',
              'Creative and elegant',
              const Color(0xFF9C27B0),
              'purple',
              themeProvider.colorScheme,
              (scheme) => themeProvider.setColorScheme(scheme),
            ),
            const Divider(),
            _buildColorSchemeOption(
              'Orange Energy',
              'Vibrant and energetic',
              const Color(0xFFFF9800),
              'orange',
              themeProvider.colorScheme,
              (scheme) => themeProvider.setColorScheme(scheme),
            ),
            const Divider(),
            _buildColorSchemeOption(
              'Red Passion',
              'Bold and dynamic',
              const Color(0xFFF44336),
              'red',
              themeProvider.colorScheme,
              (scheme) => themeProvider.setColorScheme(scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSchemeOption(
    String title,
    String description,
    Color color,
    String scheme,
    String currentScheme,
    Function(String) onTap,
  ) {
    final isSelected = currentScheme == scheme;
    return InkWell(
      onTap: () => onTap(scheme),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: isSelected 
                    ? Border.all(color: AppTheme.primaryColor, width: 2)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomColorsSection(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildColorPicker(
              'Primary Color',
              themeProvider.customPrimaryColor,
              (color) => themeProvider.setCustomPrimaryColor(color),
            ),
            const SizedBox(height: 16),
            _buildColorPicker(
              'Secondary Color',
              themeProvider.customSecondaryColor,
              (color) => themeProvider.setCustomSecondaryColor(color),
            ),
            const SizedBox(height: 16),
            _buildColorPicker(
              'Accent Color',
              themeProvider.customAccentColor,
              (color) => themeProvider.setCustomAccentColor(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(String label, Color currentColor, Function(Color) onColorChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => _showColorPicker(currentColor, onColorChanged),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showColorPicker(currentColor, onColorChanged),
              child: const Text('Change'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewSection(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildPreviewCard(),
            const SizedBox(height: 12),
            _buildPreviewButtons(),
            const SizedBox(height: 12),
            _buildPreviewText(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Document Processing',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your interface will look with the selected theme.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Primary Button'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
          ),
          child: const Text('Secondary Button'),
        ),
      ],
    );
  }

  Widget _buildPreviewText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heading Text',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Body text with normal weight and color.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Secondary text with muted color.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilitySection(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAccessibilityOption(
              'High Contrast',
              'Increases contrast for better visibility',
              Icons.contrast,
              themeProvider.highContrast,
              (value) => themeProvider.setHighContrast(value),
            ),
            const Divider(),
            _buildAccessibilityOption(
              'Large Text',
              'Increases text size for better readability',
              Icons.text_increase,
              themeProvider.largeText,
              (value) => themeProvider.setLargeText(value),
            ),
            const Divider(),
            _buildAccessibilityOption(
              'Reduce Motion',
              'Reduces animations for motion sensitivity',
              Icons.motion_photos_off,
              themeProvider.reduceMotion,
              (value) => themeProvider.setReduceMotion(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilityOption(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => themeProvider.resetToDefault(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to Default'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveTheme(themeProvider),
            icon: const Icon(Icons.save),
            label: const Text('Save Theme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hslWithHue,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _saveTheme(ThemeProvider themeProvider) {
    themeProvider.saveTheme();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme saved successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}

// Simple Color Picker Widget
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final Function(Color) onColorChanged;
  final bool enableAlpha;
  final bool displayThumbColor;
  final PaletteType paletteType;
  final List<ColorLabelType> labelTypes;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    this.enableAlpha = false,
    this.displayThumbColor = true,
    this.paletteType = PaletteType.hslWithHue,
    this.labelTypes = const [],
    this.pickerAreaHeightPercent = 0.8,
  }) : super(key: key);

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color currentColor;

  @override
  void initState() {
    super.initState();
    currentColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: Column(
        children: [
          // Color preview
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Color palette
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _getColorPalette().length,
              itemBuilder: (context, index) {
                final color = _getColorPalette()[index];
                final isSelected = color == currentColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentColor = color;
                    });
                    widget.onColorChanged(color);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: isSelected 
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getColorPalette() {
    return [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
      Colors.white,
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.indigo.shade300,
      Colors.cyan.shade300,
      Colors.lime.shade300,
      Colors.amber.shade300,
      Colors.deepOrange.shade300,
    ];
  }
}

enum PaletteType { hslWithHue, hslWithSaturation, hslWithLightness }
enum ColorLabelType { hue, saturation, lightness, alpha }
