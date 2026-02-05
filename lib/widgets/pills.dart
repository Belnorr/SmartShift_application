import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Pills extends StatelessWidget {
  final List<String> items;
  final bool wrap;
  const Pills({super.key, required this.items, this.wrap = true});

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    final chips = items.map((t) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: ss.primarySoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7E5EE)),
        ),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: ss.text,
          ),
        ),
      );
    }).toList();

    if (!wrap) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _spaced(chips, 8)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  List<Widget> _spaced(List<Widget> w, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < w.length; i++) {
      out.add(w[i]);
      if (i != w.length - 1) out.add(SizedBox(width: gap));
    }
    return out;
  }
}
