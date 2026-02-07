import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '/widgets/discover/search_bar_widget.dart';
import '/widgets/discover/shift_card.dart';
import 'shift_detail_page.dart';
import '/services/shift_booking_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String query = '';
  bool showSavedOnly = false;
  final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

  final Set<String> savedShifts = {};
  Set<String> selectedSkills = {};
  RangeValues payRange = const RangeValues(8, 30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Discover Shifts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _openFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          /// SEARCH BAR
          SearchBarWidget(
            onChanged: (value) => setState(() => query = value),
          ),

          /// FILTER CHIPS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _filterChip(
                  label: 'Saved',
                  selected: showSavedOnly,
                  onTap: () =>
                      setState(() => showSavedOnly = !showSavedOnly),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: selectedSkills.isEmpty
                      ? 'Skills'
                      : selectedSkills.join(', '),
                  selected: selectedSkills.isNotEmpty,
                  onTap: () => _openFilterSheet(context),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label:
                      '\$${payRange.start.round()}–\$${payRange.end.round()}',
                  selected:
                      payRange.start != 8 || payRange.end != 30,
                  onTap: () => _openFilterSheet(context),
                ),
              ],
            ),
          ),

          /// FIRESTORE SHIFTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shifts')
                  .where('status', isEqualTo: 'open')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No shifts available'),
                  );
                }

                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final title = (data['title'] ?? '')
                      .toString()
                      .toLowerCase();
                  final location = (data['location'] ?? '')
                      .toString()
                      .toLowerCase();

                  final skills = List<String>.from(
                    data['requiredSkills'] ?? [],
                  )
                      .map((e) => e.toLowerCase())
                      .toList();

                  final q = query.toLowerCase();

                  final matchesSearch =
                      title.contains(q) ||
                      location.contains(q) ||
                      skills.join(' ').contains(q);

                  final isSaved =
                      savedShifts.contains(doc.id);
                  final matchesSaved =
                      showSavedOnly ? isSaved : true;

                  final matchesSkills =
                      selectedSkills.isEmpty ||
                      skills.any(
                        (s) => selectedSkills.any(
                          (f) =>
                              f.toLowerCase() == s,
                        ),
                      );

                  final pay = data['payPerHour'] ?? 0;
                  final matchesPay =
                      pay >= payRange.start &&
                      pay <= payRange.end;

                  return matchesSearch &&
                      matchesSaved &&
                      matchesSkills &&
                      matchesPay;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No matching shifts'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final id = doc.id;

                    /// SAFE TIMESTAMP PARSING
                    if (data['date'] == null ||
                        data['endTime'] == null) {
                      return const SizedBox();
                    }

                    final start =
                        (data['date'] as Timestamp).toDate();
                    final end =
                        (data['endTime'] as Timestamp).toDate();

                    final dateLabel =
                        DateFormat('EEE, d MMM')
                            .format(start);
                    final timeLabel =
                        '${DateFormat('h:mm a').format(start)} – '
                        '${DateFormat('h:mm a').format(end)}';

                    return Stack(
                      children: [
                        Material(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ShiftDetailPage(
                                    shift: {
                                      ...data,
                                      'id': id,
                                      'dateLabel': dateLabel,
                                      'timeLabel': timeLabel,
                                    },
                                  ),
                                ),
                              );
                            },
                            child: ShiftCard(
                              title: data['title'],
                              company: data['company'],
                              location: data['location'],
                              dateLabel: dateLabel,
                              payPerHour: data['payPerHour'],
                              urgency: data['urgency'],
                              rewardPoints:
                                  data['rewardPoints'],
                              tags: List<String>.from(
                                data['requiredSkills'],
                              ),
                              imageUrl: (data['imageURL'] ?? '').toString(),

                            ),
                          ),
                        ),

                        /// BOOKMARK
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            icon: Icon(
                              savedShifts.contains(id)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                          onPressed: () async {
                            if (currentUid == null) return; // Handle unauthenticated state

                            final isCurrentlySaved = savedShifts.contains(id);
                            
                            // 1. Optimistic UI update
                            setState(() {
                              isCurrentlySaved ? savedShifts.remove(id) : savedShifts.add(id);
                            });

                            // 2. Persistent Update in Firestore
                            // Assuming you have a 'users' collection where you store saved shift IDs
                            final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUid);

                            if (isCurrentlySaved) {
                              await userDoc.update({
                                'savedShifts': FieldValue.arrayRemove([id])
                              });
                            } else {
                              await userDoc.update({
                                'savedShifts': FieldValue.arrayUnion([id])
                              },); // Note: use set with merge:true if the doc might not exist
                            }
                          }
                            
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// FILTER CHIP
  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.blue : Colors.black,
          ),
        ),
      ),
    );
  }

  /// FILTER SHEET
  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            selectedSkills.clear();
                            payRange =
                                const RangeValues(8, 30);
                          });
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Required skills',
                    style:
                        TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      'Retail',
                      'Barista',
                      'Cashier',
                      'Packing',
                      'Events',
                      'Usher',
                      'Customer Service',
                    ].map((skill) {
                      final selected =
                          selectedSkills.contains(skill);
                      return ChoiceChip(
                        label: Text(skill),
                        selected: selected,
                        onSelected: (value) {
                          setModalState(() {
                            value
                                ? selectedSkills.add(skill)
                                : selectedSkills.remove(skill);
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Pay range (\$/hr)',
                    style:
                        TextStyle(fontWeight: FontWeight.w600),
                  ),

                  RangeSlider(
                    values: payRange,
                    min: 8,
                    max: 30,
                    divisions: 11,
                    labels: RangeLabels(
                      '\$${payRange.start.round()}',
                      '\$${payRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        payRange = values;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}