import 'package:flutter/material.dart';

class CompressionSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String label;
  final double min;
  final double max;
  final int divisions;

  const CompressionSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                divisions: divisions,
                onChanged: onChanged,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                '${value.toInt()}%',
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
