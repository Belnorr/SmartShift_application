import 'package:flutter/material.dart';
import '../../core/models/shift.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class EmployerEditShiftScreen extends StatefulWidget {
  final Shift shift;
  const EmployerEditShiftScreen({super.key, required this.shift});

  @override
  State<EmployerEditShiftScreen> createState() =>
      _EmployerEditShiftScreenState();
}

class _EmployerEditShiftScreenState extends State<EmployerEditShiftScreen> {
  // Controllers
  late final TextEditingController roleCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController storeCtrl;

  final List<String> presetThumbs = const [
    "assets/starbucks.jpg",
    "assets/muji.jpg",
    "assets/light_to_night.jpg",
  ];

  ImageProvider? get thumbnail =>
      selectedThumbPath == null ? null : AssetImage(selectedThumbPath!);

  Future<void> _pickThumbnail() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Choose a thumbnail",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110, // thumbnail size + sheet height
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presetThumbs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final path = presetThumbs[i];
                      final isSelected = path == selectedThumbPath;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(context, path),
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? context.ss.primary
                                  : const Color(0xFFE7E5EE),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(path, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (chosen != null) setState(() => selectedThumbPath = chosen);
  }

  late DateTime selectedDate;
  late TimeOfDay start;
  late TimeOfDay end;

  late double urgency;
  late int points;
  late int slotsTotal;

  late Set<String> skills;
  String? selectedThumbPath;

  final List<String> allSkills = const [
    'Retail',
    'Barista',
    'Cashier',
    'Packing',
    'Customer Service',
    'Events',
    'Usher',
  ];

  late final List<TimeOfDay> timeOptions;

  @override
  void initState() {
    super.initState();

    final s = widget.shift;

    timeOptions = _buildTimeOptions(stepMinutes: 30);

    roleCtrl = TextEditingController(text: s.title);
    locationCtrl = TextEditingController(text: s.location);
    storeCtrl = TextEditingController(text: s.shiftCode);

    selectedDate = s.date;

    start = _snapToOptions(s.start, timeOptions);
    end = _snapToOptions(s.end, timeOptions);

    urgency = (s.urgency).toDouble();
    points = s.points;
    slotsTotal = (s.slotsTotal ?? 1).clamp(1, 50);

    skills = s.skills.toSet();
    selectedThumbPath = s.thumbnailPath;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void dispose() {
    roleCtrl.dispose();
    locationCtrl.dispose();
    storeCtrl.dispose();
    super.dispose();
  }

  List<TimeOfDay> _buildTimeOptions({required int stepMinutes}) {
    final out = <TimeOfDay>[];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += stepMinutes) {
        out.add(TimeOfDay(hour: h, minute: m));
      }
    }
    return out;
  }

  TimeOfDay _snapToOptions(TimeOfDay t, List<TimeOfDay> options) {
    int minutes(TimeOfDay x) => x.hour * 60 + x.minute;
    final target = minutes(t);

    TimeOfDay best = options.first;
    int bestDiff = (minutes(best) - target).abs();

    for (final o in options) {
      final d = (minutes(o) - target).abs();
      if (d < bestDiff) {
        best = o;
        bestDiff = d;
      }
    }
    return best;
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }

  Future<void> _pickMoreSkills() async {
    final temp = Set<String>.from(skills);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Add skills",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: allSkills.map((s) {
                  final selected = temp.contains(s);
                  return FilterChip(
                    selected: selected,
                    label: Text(s),
                    onSelected: (v) {
                      if (v) {
                        temp.add(s);
                      } else {
                        temp.remove(s);
                      }
                      (ctx as Element).markNeedsBuild();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => skills = temp);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final role = roleCtrl.text.trim();
    final loc = locationCtrl.text.trim();
    final store = storeCtrl.text.trim();

    if (role.isEmpty || loc.isEmpty || store.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill Role, Location and Store/Event.")),
      );
      return;
    }

    final updated = widget.shift.copyWith(
      title: role,
      location: loc,
      date: selectedDate,
      start: start,
      end: end,
      urgency: urgency.toInt(),
      points: points,
      slotsTotal: slotsTotal,
      skills: skills.toList(),
      thumbnailPath: selectedThumbPath,
    );

    try {
      await FirestoreService.instance.updateShift(shift: updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift updated.")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Scaffold(
      backgroundColor: ss.surface,
      appBar: AppBar(
        title: const Text("Edit Shift"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ss.text,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "Apply Changes",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
            // change Thumbnail
            _PillButton(
              label: selectedThumbPath == null
                  ? "Change Thumbnail"
                  : "Thumbnail selected",
              icon: Icons.upload_rounded,
              onTap: _pickThumbnail,
            ),

            const SizedBox(height: 10),

            _Card(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE7E5EE)),
                      image: thumbnail == null
                          ? null
                          : DecorationImage(
                              image: thumbnail!, fit: BoxFit.cover),
                    ),
                    child: thumbnail == null
                        ? const Icon(Icons.photo_outlined,
                            color: Color(0xFF94A3B8))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      thumbnail == null
                          ? "No thumbnail selected"
                          : "Thumbnail selected",
                      style: TextStyle(
                        color: context.ss.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (thumbnail != null)
                    TextButton(
                      onPressed: () => setState(() => selectedThumbPath = null),
                      child: const Text("Clear",
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _LabeledField(label: "Role", controller: roleCtrl),
            const SizedBox(height: 10),
            _LabeledField(label: "Location", controller: locationCtrl),
            const SizedBox(height: 10),
            _LabeledField(label: "Store / Event Name", controller: storeCtrl),

            const SizedBox(height: 18),

            const Text(
              "Pick Date",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _Card(
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                onDateChanged: (d) => setState(() => selectedDate = d),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Shift Timing",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: _TimeDropdown(
                      value: start,
                      options: timeOptions,
                      label: "Start",
                      fmt: _fmtTime,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => start = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeDropdown(
                      value: end,
                      options: timeOptions,
                      label: "End",
                      fmt: _fmtTime,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => end = v);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Required Skills",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allSkills.map((s) {
                      final selected = skills.contains(s);
                      return FilterChip(
                        selected: selected,
                        label: Text(s),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              skills.add(s);
                            } else {
                              skills.remove(s);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _pickMoreSkills,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      "Add more",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "People Needed",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _Card(
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6E8EE)),
                    ),
                    child: Text(
                      '$slotsTotal',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => setState(
                        () => slotsTotal = (slotsTotal - 1).clamp(1, 50)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE6E8EE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('- 1',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => setState(
                        () => slotsTotal = (slotsTotal + 1).clamp(1, 50)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE6E8EE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('+ 1',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Urgency:",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _Card(
              child: Slider(
                value: urgency.clamp(0, 5),
                min: 0,
                max: 5,
                divisions: 5,
                label: urgency.toInt().toString(),
                onChanged: (v) => setState(() => urgency = v),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// ---------- UI helpers ----------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: child,
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ss.text,
          side: const BorderSide(color: Color(0xFFE6E8EE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _LabeledField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: ss.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E8EE)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: controller,
              autofocus: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String label;
  final TimeOfDay value;
  final List<TimeOfDay> options;
  final String Function(TimeOfDay) fmt;
  final ValueChanged<TimeOfDay?> onChanged;

  const _TimeDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.fmt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeOfDay>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: options.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(fmt(t),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
