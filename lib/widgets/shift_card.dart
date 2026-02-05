import 'package:flutter/material.dart';
import '../core/models/shift.dart';
import '../theme/app_theme.dart';
import 'pills.dart';

class ShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final bool showProgress;
  final bool compact;

  const ShiftCard({
    super.key,
    required this.shift,
    this.onTap,
    this.onMore,
    this.showProgress = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    Color urgencyColor(int u) {
      if (u >= 5) return const Color(0xFFE6484D);
      if (u >= 4) return const Color(0xFFFF7A00);
      if (u >= 3) return const Color(0xFF7C5CFF);
      if (u >= 2) return const Color(0xFF3E7BFA);
      return const Color(0xFF16A34A);
    }

    String dateLabel(DateTime d) {
      const wd = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      const mo = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      return "${wd[d.weekday - 1]} ${d.day} ${mo[d.month - 1]}";
    }

    String timeLabel(TimeOfDay start, TimeOfDay end) {
      String fmt(TimeOfDay t) {
        final hh = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
        final mm = t.minute.toString().padLeft(2, '0');
        final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
        return '$hh:$mm $ap';
      }

      return "${fmt(start)} - ${fmt(end)}";
    }

    double progressValue(int booked, int total) {
      if (total <= 0) return 0.0; // avoid division-by-zero
      final v = booked / total;
      if (v.isNaN || v.isInfinite) return 0.0;
      return v.clamp(0.0, 1.0);
    }

    final uColor = urgencyColor(shift.urgency);
    final dLabel = dateLabel(shift.date);
    final tLabel = timeLabel(shift.start, shift.end);
    final prog = progressValue(shift.slotsBooked, shift.slotsTotal);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: ss.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7E5EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shift.title,
                    style: TextStyle(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w900,
                      color: ss.text,
                    ),
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: const Icon(Icons.more_horiz),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              shift.employer,
              style: TextStyle(
                color: ss.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _tag(context, Icons.place, shift.location),
                const SizedBox(width: 10),
                _tag(context, Icons.calendar_today, '$dLabel  •  $tLabel'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _pillBadge(context, 'Urgency ${shift.urgency}/5', uColor),
                const SizedBox(width: 8),
                _pillBadge(context, '${shift.points} pts', ss.primary),
                const Spacer(),
                Text(
                  '\$${shift.hourlyRate.toStringAsFixed(0)}/h',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ss.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Pills(items: shift.skills, wrap: false),
            if (showProgress) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: prog,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0EFF6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${shift.slotsBooked}/${shift.slotsTotal}',
                    style:
                        TextStyle(color: ss.muted, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, IconData icon, String text) {
    final ss = context.ss;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ss.muted),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: ss.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _pillBadge(BuildContext context, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E5EE)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}
