import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/shift.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  bool _showFilter = false;
  RangeValues _urgency = const RangeValues(0, 5);
  RangeValues _points = const RangeValues(0, 200);
  RangeValues _hourlyRate = const RangeValues(0, 30);
  RangeValues _daysAhead = const RangeValues(0, 30);

  bool _onlyOngoing = true;
  bool _onlyWithVacancy = false;

  List<Shift> _applyFilters(List<Shift> all) {
    final now = DateTime.now();

    return all.where((s) {
      if (_onlyOngoing &&
          !(s.status == ShiftStatus.ongoing || s.status == ShiftStatus.open)) {
        return false;
      }

      if (_onlyWithVacancy && s.slotsBooked >= s.slotsTotal) return false;

      final u = (s.urgency).toDouble();
      if (u < _urgency.start || u > _urgency.end) return false;

      final p = (s.points).toDouble();
      if (p < _points.start || p > _points.end) return false;

      final r = (s.hourlyRate).toDouble();
      if (r < _hourlyRate.start || r > _hourlyRate.end) return false;

      final days = s.date.difference(now).inDays.toDouble();
      if (days < _daysAhead.start || days > _daysAhead.end) return false;

      return true;
    }).toList();
  }

  void _toggleFilter() => setState(() => _showFilter = !_showFilter);

  void _resetFilters() {
    setState(() {
      _urgency = const RangeValues(0, 5);
      _points = const RangeValues(0, 200);
      _hourlyRate = const RangeValues(0, 30);
      _daysAhead = const RangeValues(0, 30);
      _onlyOngoing = true;
      _onlyWithVacancy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;
    final db = FirestoreService.instance;

    return Scaffold(
      backgroundColor: ss.surface,
      appBar: AppBar(
        title: const Text("Employer Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ss.text,
        actions: [
  IconButton(
    tooltip: "Sign Out",
    icon: const Icon(Icons.logout_rounded, size: 20),
    onPressed: () async {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        context.go('/'); // <- IMPORTANT
      }
    },
  ),
  const SizedBox(width: 8),
],

      ),
      body: StreamBuilder<List<Shift>>(
        stream: db.getEmployerShifts(),
        initialData: const [], // ✅ prevents endless spinner if stream is empty
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                "Firestore error:\n${snap.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final all = snap.data ?? const <Shift>[];
          final filtered = _applyFilters(all);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                children: [
                  _SummaryCard(shifts: filtered),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: "Booking Process",
                    rightText: "Filter",
                    onRightTap: _toggleFilter,
                  ),
                  const SizedBox(height: 10),
                  if (filtered.isEmpty)
                    _EmptyStateCard(
                      title: "No shifts match your filters",
                      subtitle: "Try widening the urgency/points/rate ranges.",
                      onReset: _resetFilters,
                    )
                  else
                    ...filtered.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingCard(
                          shift: s,
                          thumbnailAsset: (s.thumbnailPath?.isNotEmpty ?? false)
                              ? s.thumbnailPath!
                              : _thumbForEmployer(s.employer),
                        ),
                      ),
                    ),
                ],
              ),
              if (_showFilter)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleFilter,
                    child: Container(color: Colors.black.withOpacity(0.12)),
                  ),
                ),
              if (_showFilter)
                Positioned(
                  top: 92,
                  right: 16,
                  left: 16,
                  child: _FilterPanel(
                    urgency: _urgency,
                    points: _points,
                    hourlyRate: _hourlyRate,
                    daysAhead: _daysAhead,
                    onlyOngoing: _onlyOngoing,
                    onlyWithVacancy: _onlyWithVacancy,
                    onUrgencyChanged: (v) => setState(() => _urgency = v),
                    onPointsChanged: (v) => setState(() => _points = v),
                    onHourlyRateChanged: (v) => setState(() => _hourlyRate = v),
                    onDaysAheadChanged: (v) => setState(() => _daysAhead = v),
                    onOnlyOngoingChanged: (v) =>
                        setState(() => _onlyOngoing = v),
                    onOnlyWithVacancyChanged: (v) =>
                        setState(() => _onlyWithVacancy = v),
                    onReset: _resetFilters,
                    onClose: _toggleFilter,
                    primary: ss.primary,
                    text: ss.text,
                    muted: ss.muted,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _thumbForEmployer(String employer) {
    final e = employer.toLowerCase();
    if (e.contains("starbucks")) return "assets/img/starbucks.jpg";
    if (e.contains("muji")) return "assets/img/muji.jpg";
    if (e.contains("light")) return "assets/img/light_to_night.jpg";
    if (e.contains("yakun")) return "assets/img/yakun.jpg";
    if (e.contains("uniqlo")) return "assets/img/uniqlo.jpg";
    if (e.contains("chateraise")) return "assets/img/chateraise.jpg";
    if (e.contains("bread")) return "assets/img/break_talk.jpg";
    return "assets/img/auth_bg.png";
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Shift> shifts;
  const _SummaryCard({required this.shifts});

  @override
  Widget build(BuildContext context) {
    final open = shifts
        .where((s) =>
            s.status == ShiftStatus.open || s.status == ShiftStatus.ongoing)
        .length;

    final booked = shifts.where((s) => s.slotsBooked >= s.slotsTotal).length;

    final urgent = shifts
        .where((s) =>
            (s.status == ShiftStatus.open || s.status == ShiftStatus.ongoing) &&
            s.urgency >= 4)
        .length;

    final noShows = shifts.where((s) => s.status == ShiftStatus.noshow).length;

    final totalForDonut = open + booked;

    final showEmptyDonut = totalForDonut == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E243A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 30,
                sections: showEmptyDonut
                    ? [
                        PieChartSectionData(
                          value: 1,
                          color: const Color(0xFF334155),
                          radius: 18,
                          showTitle: false,
                        ),
                      ]
                    : [
                        PieChartSectionData(
                          value: open.toDouble(),
                          color: const Color(0xFF3B82F6),
                          radius: 18,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: booked.toDouble(),
                          color: const Color(0xFFEF4444),
                          radius: 18,
                          showTitle: false,
                        ),
                      ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _KpiTile(title: "Open Shifts", value: "$open")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _KpiTile(title: "Booked", value: "$booked")),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _KpiTile(title: "Urgent", value: "$urgent")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _KpiTile(title: "No-shows", value: "$noShows")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String title;
  final String value;

  const _KpiTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String rightText;
  final VoidCallback onRightTap;

  const _SectionHeader({
    required this.title,
    required this.rightText,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: ss.text,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onRightTap,
          icon: const Icon(Icons.filter_alt_outlined, size: 18),
          label: Text(
            rightText,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          style: TextButton.styleFrom(
            foregroundColor: ss.text,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Shift shift;
  final String thumbnailAsset;

  const _BookingCard({required this.shift, required this.thumbnailAsset});

  @override
  Widget build(BuildContext context) {
    final dateLabel = _fmtDate(shift.date);
    final timeLabel = "${_fmtTime(shift.start)} - ${_fmtTime(shift.end)}";
    final urgency = (shift.urgency).clamp(0, 5);
    final urgencyColor = _urgencyColor(urgency);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6E8EE)),
              image: DecorationImage(
                image: AssetImage(thumbnailAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${shift.shiftCode}  ${shift.title}",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: urgencyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Urgency $urgency",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: urgencyColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${shift.employer} • ${shift.location}",
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "$dateLabel  $timeLabel",
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniPill(
                      label: "${shift.points} pts",
                      icon: Icons.stars_rounded,
                    ),
                    const SizedBox(width: 8),
                    _MiniPill(
                      label: "\$${shift.hourlyRate}/hr",
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(width: 8),
                    _MiniPill(
                      label: "${shift.slotsBooked}/${shift.slotsTotal}",
                      icon: Icons.people_alt_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(int u) {
    switch (u) {
      case 0:
      case 1:
        return const Color(0xFF22C55E);
      case 2:
        return const Color(0xFFEAB308);
      case 3:
        return const Color(0xFFF97316);
      case 4:
      case 5:
      default:
        return const Color(0xFFEF4444);
    }
  }

  String _fmtDate(DateTime d) {
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
    return "${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]}";
  }

  String _fmtTime(TimeOfDay t) {
    final hh = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, "0");
    final ap = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hh:$mm $ap";
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF334155)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final RangeValues urgency;
  final RangeValues points;
  final RangeValues hourlyRate;
  final RangeValues daysAhead;

  final bool onlyOngoing;
  final bool onlyWithVacancy;

  final ValueChanged<RangeValues> onUrgencyChanged;
  final ValueChanged<RangeValues> onPointsChanged;
  final ValueChanged<RangeValues> onHourlyRateChanged;
  final ValueChanged<RangeValues> onDaysAheadChanged;

  final ValueChanged<bool> onOnlyOngoingChanged;
  final ValueChanged<bool> onOnlyWithVacancyChanged;

  final VoidCallback onReset;
  final VoidCallback onClose;

  final Color primary;
  final Color text;
  final Color muted;

  const _FilterPanel({
    required this.urgency,
    required this.points,
    required this.hourlyRate,
    required this.daysAhead,
    required this.onlyOngoing,
    required this.onlyWithVacancy,
    required this.onUrgencyChanged,
    required this.onPointsChanged,
    required this.onHourlyRateChanged,
    required this.onDaysAheadChanged,
    required this.onOnlyOngoingChanged,
    required this.onOnlyWithVacancyChanged,
    required this.onReset,
    required this.onClose,
    required this.primary,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6E8EE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Filters",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: text,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onReset,
                  child: Text(
                    "Reset",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF0F172A),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 6),
            _FilterRange(
              title: "Urgency",
              subtitle: "${urgency.start.toInt()} - ${urgency.end.toInt()}",
              min: 0,
              max: 5,
              divisions: 5,
              values: urgency,
              onChanged: onUrgencyChanged,
              primary: primary,
              muted: muted,
            ),
            _FilterRange(
              title: "Reward Points",
              subtitle: "${points.start.toInt()} - ${points.end.toInt()}",
              min: 0,
              max: 200,
              divisions: 40,
              values: points,
              onChanged: onPointsChanged,
              primary: primary,
              muted: muted,
            ),
            _FilterRange(
              title: "Hourly Rate",
              subtitle:
                  "\$${hourlyRate.start.toInt()} - \$${hourlyRate.end.toInt()}",
              min: 0,
              max: 30,
              divisions: 30,
              values: hourlyRate,
              onChanged: onHourlyRateChanged,
              primary: primary,
              muted: muted,
            ),
            _FilterRange(
              title: "Days Ahead",
              subtitle:
                  "${daysAhead.start.toInt()} - ${daysAhead.end.toInt()} days",
              min: 0,
              max: 30,
              divisions: 30,
              values: daysAhead,
              onChanged: onDaysAheadChanged,
              primary: primary,
              muted: muted,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ToggleTile(
                    title: "Ongoing only",
                    value: onlyOngoing,
                    onChanged: onOnlyOngoingChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToggleTile(
                    title: "Has vacancy",
                    value: onlyWithVacancy,
                    onChanged: onOnlyWithVacancyChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRange extends StatelessWidget {
  final String title;
  final String subtitle;
  final double min;
  final double max;
  final int divisions;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final Color primary;
  final Color muted;

  const _FilterRange({
    required this.title,
    required this.subtitle,
    required this.min,
    required this.max,
    required this.divisions,
    required this.values,
    required this.onChanged,
    required this.primary,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(
                subtitle,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primary,
              inactiveTrackColor: const Color(0xFFE6E8EE),
              thumbColor: primary,
              overlayColor: primary.withOpacity(0.15),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 9,
              ),
              trackHeight: 4,
            ),
            child: RangeSlider(
              values: values,
              min: min,
              max: max,
              divisions: divisions,
              labels: RangeLabels(
                values.start.toStringAsFixed(0),
                values.end.toStringAsFixed(0),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: ss.text,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onReset;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w900, color: ss.text)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: ss.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(color: Color(0xFFE6E8EE)),
            ),
            child: const Text(
              "Reset Filters",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
