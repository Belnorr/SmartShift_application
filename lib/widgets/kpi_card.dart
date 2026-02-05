import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ss.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (color ?? ss.primary).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color ?? ss.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: ss.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                      color: ss.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
