import 'package:flutter/material.dart';

class Segmented extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const Segmented({
    super.key,
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (int i = 0; i < labels.length; i++)
          ButtonSegment<int>(
            value: i,
            label: Text(labels[i]),
          ),
      ],
      selected: {index},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}
