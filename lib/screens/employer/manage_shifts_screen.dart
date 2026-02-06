import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/shift.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'edit_shift_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class EmployerManageShiftsScreen extends StatefulWidget {
  const EmployerManageShiftsScreen({super.key});

  @override
  State<EmployerManageShiftsScreen> createState() =>
      _EmployerManageShiftsScreenState();
}

class _EmployerManageShiftsScreenState
    extends State<EmployerManageShiftsScreen> {
  final _search = TextEditingController();

  int seg = 0;

  bool _isOngoing(Shift s) =>
      s.status == ShiftStatus.ongoing || s.status == ShiftStatus.open;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Shift> _applySearchAndSegment(List<Shift> all) {
    final q = _search.text.trim().toLowerCase();

    final bySeg = all.where((s) => seg == 0 ? _isOngoing(s) : !_isOngoing(s));

    if (q.isEmpty) return bySeg.toList();

    return bySeg.where((s) {
      final id = s.id.toLowerCase();
      final title = (s.title).toLowerCase();
      return id.contains(q) || title.contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(Shift shift) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Delete shift?"),
        content: Text("This will delete ${shift.shiftCode} (${shift.title})."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirestoreService.instance.deleteShift(shiftId: shift.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shift deleted.")),
      );
    } catch (e, st) {
      debugPrint("DELETE FAILED: $e");
      debugPrint("$st");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  void _openEdit(Shift shift) {
    Future.microtask(() {
      if (!mounted) return;
      context.push('/e/edit', extra: shift);
    });
  }

  void _showCardMenu({
    required TapDownDetails details,
    required Shift shift,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(
      details.globalPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: context,
      position: pos,
      items: const [
        PopupMenuItem(value: "edit", child: Text("Edit")),
        PopupMenuItem(value: "delete", child: Text("Delete")),
      ],
    );

    if (!mounted) return;

    if (choice == "edit") {
      _openEdit(shift);
    } else if (choice == "delete") {
      _confirmDelete(shift);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;
    final db = FirestoreService.instance;

    return Scaffold(
      backgroundColor: ss.surface,
      appBar: AppBar(
        title: const Text("Manage Shifts"),
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
                context.go('/');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE6E8EE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: "Search by shift number or name",
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SegmentedPills(
              index: seg,
              labels: const ["ongoing", "completed"],
              onChanged: (i) => setState(() => seg = i),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Shift>>(
                stream: db.getEmployerShifts(),
                initialData: const [],
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        "Firestore error:\n${snap.error}",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final data = snap.data ?? const <Shift>[];
                  final shown = _applySearchAndSegment(data);

                  if (shown.isEmpty) {
                    return Center(
                      child: Text(
                        seg == 0 ? "No ongoing shifts" : "No completed shifts",
                        style: TextStyle(
                          color: ss.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = shown[i];
                      return _ManageShiftCard(
                        shift: s,
                        onDotsTapDown: (d) =>
                            _showCardMenu(details: d, shift: s),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- UI widgets ---

class _IconPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _IconPillButton({
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
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ss.text,
          side: const BorderSide(color: Color(0xFFE6E8EE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _SegmentedPills extends StatelessWidget {
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _SegmentedPills({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: selected ? ss.text : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ManageShiftCard extends StatelessWidget {
  final Shift shift;
  final GestureTapDownCallback onDotsTapDown;

  const _ManageShiftCard({
    required this.shift,
    required this.onDotsTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final ss = context.ss;

    final urgency = (shift.urgency ?? 0).clamp(0, 5);
    final color = _urgencyColor(urgency);

    final booked = shift.slotsBooked ?? 0;
    final total = shift.slotsTotal ?? 0;
    final waitlist = 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E8EE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Shift ${shift.shiftCode}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ss.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Booked: $booked/$total | Waitlist: $waitlist",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ss.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Status: ${shift.status.name}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ss.muted,
                  ),
                ),
              ],
            ),
          ),

          // urgency pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Text(
              "Urgency $urgency/5",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: color,
              ),
            ),
          ),

          const SizedBox(width: 10),

          GestureDetector(
            onTapDown: onDotsTapDown,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.more_vert, size: 20),
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
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFFF97316);
      case 4:
      case 5:
      default:
        return const Color(0xFFEF4444);
    }
  }
}
