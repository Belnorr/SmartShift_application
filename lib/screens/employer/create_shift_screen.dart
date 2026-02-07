// ignore_for_file: unused_element_parameter
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';

import '../../core/models/shift.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pills.dart';

class CreateShiftScreen extends StatefulWidget {
  const CreateShiftScreen({super.key});

  @override
  State<CreateShiftScreen> createState() => _CreateShiftScreenState();
}

class _CreateShiftScreenState extends State<CreateShiftScreen> {
  final title = TextEditingController();
  final location = TextEditingController();
  final payCtrl = TextEditingController(text: '12'); // default
  final ScrollController _thumbCtrl = ScrollController();

  DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);

  double urgency = 3;
  @override
  void dispose() {
    payCtrl.dispose();
    _thumbCtrl.dispose();
    title.dispose();
    location.dispose();
    super.dispose();
  }

  final List<String> allSkills = const [
    'Retail',
    'Barista',
    'Cashier',
    'Packing',
    'Customer Service',
    'Events',
    'Usher',
  ];
  final Set<String> skills = {'Retail', 'Cashier'};

  int points = 45;
  int slotsTotal = 3;

  final List<String> presetThumbs = const [
    "assets/starbucks.jpg",
    "assets/muji.jpg",
    "assets/light_to_night.jpg",
    "assets/bread_talk.jpg",
    "assets/chateraise.jpg",
    "assets/uniqlo.jpg",
    "assets/yakun.jpg",
  ];

  String? selectedThumbPath;
  ImageProvider? get thumbnail =>
      selectedThumbPath == null ? null : AssetImage(selectedThumbPath!);

  Future<void> _pickThumbnail() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (ctx) {
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
                  height: 110,
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        final next = (_thumbCtrl.offset + event.scrollDelta.dy)
                            .clamp(0.0, _thumbCtrl.position.maxScrollExtent);
                        _thumbCtrl.jumpTo(next);
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) {
                        final next = (_thumbCtrl.offset - details.delta.dx)
                            .clamp(0.0, _thumbCtrl.position.maxScrollExtent);
                        _thumbCtrl.jumpTo(next);
                      },
                      child: ListView.separated(
                        controller: _thumbCtrl,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: presetThumbs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final path = presetThumbs[i];
                          final isSelected = path == selectedThumbPath;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(ctx, path),
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

  Future<void> _createShift() async {
    final t = title.text.trim();
    final loc = location.text.trim();

    if (t.isEmpty || loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in Shift Title + Location")),
      );
      return;
    }

    final pay = int.tryParse(payCtrl.text.trim()) ?? 0;

if (pay <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Please enter a valid pay per hour (> 0)")),
  );
  return;
}


    try {
      await FirestoreService.instance.createShift(
        title: t,
        location: loc,
        date: selectedDate,
        start: start,
        end: end,
        urgency: urgency.toInt(),
        points: points,
        skills: skills.toList(),
        slotsTotal: slotsTotal,
        thumbnailPath: selectedThumbPath,
        payPerHour: pay,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift created.")),
      );

      if (!mounted) return;

      final state = GoRouterState.of(context);
      final from = state.uri.queryParameters['from'];

      if (from != null && from.isNotEmpty) {
        context.go(Uri.decodeComponent(from));
      } else {
        context.go('/e/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Create failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Scaffold(
      backgroundColor: ss.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final state = GoRouterState.of(context);
                    final from = state.uri.queryParameters['from'];
                    if (from != null && from.isNotEmpty) {
                      context.go(Uri.decodeComponent(from));
                    } else {
                      context.go('/e/dashboard');
                    }
                  },
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 18,
                  tooltip: "Close",
                ),
                Text(
                  'Create Shift',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ss.text,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _pickThumbnail,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(selectedThumbPath == null
                      ? 'Upload Thumbnail'
                      : 'Change Thumbnail'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                    side: const BorderSide(color: Color(0xFFE7E5EE)),
                    backgroundColor: Colors.white,
                    foregroundColor: ss.text,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
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
                          ? "No thumbnail uploaded"
                          : "Thumbnail selected",
                      style: TextStyle(
                        color: ss.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (thumbnail != null)
                    TextButton(
                      onPressed: () => setState(() => selectedThumbPath = null),
                      child: const Text(
                        "Clear",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _CapsuleField(
              label: 'Shift Title',
              controller: title,
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 10),
            _CapsuleField(
              label: 'Location',
              controller: location,
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 16),
            Text(
              'Pick Date',
              style: TextStyle(fontWeight: FontWeight.w900, color: ss.text),
            ),
            const SizedBox(height: 8),

            _Card(
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: ss.primary,
                      ),
                ),
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onDateChanged: (d) => setState(() => selectedDate = d),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Shift Timing',
              style: TextStyle(fontWeight: FontWeight.w900, color: ss.text),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Start: ${_fmt(start)}',
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: start);
                      if (t != null) setState(() => start = t);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PillButton(
                    label: 'End: ${_fmt(end)}',
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: end);
                      if (t != null) setState(() => end = t);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            _CapsuleField(
              label: 'Pay per hour (\$/h)',
              controller: payCtrl,
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            Text(
              'Required Skills',
              style: TextStyle(fontWeight: FontWeight.w900, color: ss.text),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allSkills.map((s) {
                final selected = skills.contains(s);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      skills.remove(s);
                    } else {
                      skills.add(s);
                    }
                  }),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? ss.primary : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE7E5EE)),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color: selected ? Colors.white : ss.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  'People Needed',
                  style: TextStyle(fontWeight: FontWeight.w900, color: ss.text),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE7E5EE)),
                  ),
                  child: Text(
                    '$slotsTotal',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: ss.text,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => setState(
                        () => slotsTotal = (slotsTotal - 1).clamp(1, 50)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE7E5EE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white,
                      foregroundColor: ss.text,
                    ),
                    child: const Text('- 1',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => setState(
                        () => slotsTotal = (slotsTotal + 1).clamp(1, 50)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE7E5EE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white,
                      foregroundColor: ss.text,
                    ),
                    child: const Text('+ 1',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Urgency',
                  style: TextStyle(fontWeight: FontWeight.w900, color: ss.text),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE7E5EE)),
                  ),
                  child: Text(
                    '${urgency.toInt()}/5',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: ss.text,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: ss.primary,
                inactiveTrackColor: const Color(0xFFE7E5EE),
                thumbColor: ss.primary,
                overlayColor: ss.primary.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: urgency,
                onChanged: (v) => setState(() => urgency = v),
                min: 0,
                max: 5,
                divisions: 5,
              ),
            ),

            const SizedBox(height: 12),

            // Reward points row (Card + Decrease + Increase)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reward Points',
                          style: TextStyle(
                            color: ss.muted,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$points',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: ss.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                SizedBox(
                  width: 140,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(
                              () => points = (points + 5).clamp(0, 200)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFFE7E5EE)),
                            foregroundColor: ss.text,
                            backgroundColor: Colors.white,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          child: const Text('+ Increase'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(
                              () => points = (points - 5).clamp(0, 200)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: const BorderSide(color: Color(0xFFE7E5EE)),
                            foregroundColor: Colors.redAccent,
                            backgroundColor: Colors.white,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          child: const Text('- Decrease'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'Preview Skills',
              style: TextStyle(fontWeight: FontWeight.w900, color: ss.text),
            ),
            const SizedBox(height: 10),
            Pills(items: skills.toList()),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _createShift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Create Shift',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(TimeOfDay t) {
    final hh = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hh:$mm $ap';
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CapsuleField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _CapsuleField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E5EE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.white,
        foregroundColor: ss.text,
        side: const BorderSide(color: Color(0xFFE7E5EE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
      child: Text(label),
    );
  }
}
