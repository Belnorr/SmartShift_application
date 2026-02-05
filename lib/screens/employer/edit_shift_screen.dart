import 'package:flutter/material.dart';
import '../../core/models/shift.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class EmployerEditShiftScreen extends StatefulWidget {
  final Shift shift;
  const EmployerEditShiftScreen({super.key, required this.shift});

  @override
  State<EmployerEditShiftScreen> createState() => _EmployerEditShiftScreenState();
}

class _EmployerEditShiftScreenState extends State<EmployerEditShiftScreen> {
  late final TextEditingController title;
  late final TextEditingController location;

  late DateTime selectedDate;
  late TimeOfDay start;
  late TimeOfDay end;

  late double urgency;
  late int points;

  late Set<String> skills;
  String? selectedThumbPath;

  final List<String> allSkills = const [
    'Retail', 'Barista', 'Cashier', 'Packing', 'Customer Service', 'Events', 'Usher',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.shift;

    title = TextEditingController(text: s.title);
    location = TextEditingController(text: s.location);

    selectedDate = s.date;
    start = s.start;
    end = s.end;

    urgency = (s.urgency).toDouble();
    points = s.points;

    skills = s.skills.toSet();
    selectedThumbPath = s.thumbnailPath;
  }

  @override
  void dispose() {
    title.dispose();
    location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = title.text.trim();
    final loc = location.text.trim();

    if (t.isEmpty || loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill title + location")),
      );
      return;
    }

    final updated = widget.shift.copyWith(
      title: t,
      location: loc,
      date: selectedDate,
      start: start,
      end: end,
      urgency: urgency.toInt(),
      points: points,
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
        title: Text("Edit ${widget.shift.id}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ss.text,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w900)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          _CapsuleField(label: "Shift Title", controller: title, icon: Icons.work_outline),
          const SizedBox(height: 10),
          _CapsuleField(label: "Location", controller: location, icon: Icons.location_on_outlined),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CapsuleField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _CapsuleField({
    required this.label,
    required this.controller,
    required this.icon,
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
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
