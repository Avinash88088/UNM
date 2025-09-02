import 'package:flutter/material.dart';

class EnhancementControls extends StatelessWidget {
  final double brightness;
  final double contrast;
  final double saturation;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onSaturationChanged;
  final VoidCallback onReset;

  const EnhancementControls({
    Key? key,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onSaturationChanged,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enhancement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: onReset,
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSlider(
          context: context,
          label: 'Brightness',
          value: brightness,
          min: -1.0,
          max: 1.0,
          onChanged: onBrightnessChanged,
        ),
        const SizedBox(height: 16),
        _buildSlider(
          context: context,
          label: 'Contrast',
          value: contrast,
          min: -1.0,
          max: 1.0,
          onChanged: onContrastChanged,
        ),
        const SizedBox(height: 16),
        _buildSlider(
          context: context,
          label: 'Saturation',
          value: saturation,
          min: -1.0,
          max: 1.0,
          onChanged: onSaturationChanged,
        ),
      ],
    );
  }

  Widget _buildSlider({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: 200,
                onChanged: onChanged,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                value.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
