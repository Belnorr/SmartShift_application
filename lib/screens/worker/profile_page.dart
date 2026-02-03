import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartshift_application2/screens/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static String get uid =>
      FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(data: data),
                    const SizedBox(height: 20),
                    _SummaryCard(stats: data['stats'] ?? {}),
                    const SizedBox(height: 20),
                    _SkillsSection(skills: List.from(data['skills'] ?? [])),

                    // LOGOUT BUTTON — LINE ~68
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],

            ),
          );
        },
      ),
    );
  }
}

/* =========================
   PROFILE HEADER
========================= */

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProfileHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final photo = data['photoURL'] ?? '';
    final name = data['name'] ?? '';
    final followers = data['followersCount'] ?? 0;
    final following = data['followingCount'] ?? 0;
    final reliability = data['reliability'] ?? 0;
    final points = data['points'] ?? 0;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _openEditProfile(context),
          child: CircleAvatar(
            radius: 42,
            backgroundImage:
                photo.isNotEmpty ? AssetImage(photo) : null,
            child: photo.isEmpty
                ? const Icon(Icons.person, size: 42)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(label: 'Following', value: following.toString()),
            const SizedBox(width: 24),
            _StatItem(label: 'Followers', value: followers.toString()),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Badge(
              icon: Icons.verified,
              label: 'Reliability $reliability%',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _Badge(
              icon: Icons.stars,
              label: '$points PTS',
              color: Colors.indigo,
            ),
          ],
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            onPressed: () => _openEditProfile(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _EditProfileSheet(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   SUMMARY CARD
========================= */

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _SummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final completed = stats['shiftsCompleted'] ?? 0;
    final late = stats['lateCancellations'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24),
          _SummaryRow(
            label: 'Shifts completed',
            value: completed.toString(),
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Late cancellation penalties',
            value: late.toString(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/* =========================
   SKILLS SECTION
========================= */

class _SkillsSection extends StatelessWidget {
  final List skills;

  const _SkillsSection({required this.skills});

  Color _skillColor(String skill) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[skill.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            final color = _skillColor(skill.toString());
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                skill.toString().trim(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/* =========================
   EDIT PROFILE SHEET
========================= */

class _EditProfileSheet extends StatelessWidget {
  const _EditProfileSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Change profile picture'),
            onTap: () {
              Navigator.pop(context);
              _openPhotoPicker(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Edit skills'),
            onTap: () {
              Navigator.pop(context);
              _openSkillsEditor(context);
            },
          ),
        ],
      ),
    );
  }

  void _openPhotoPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                title: const Text('Default'),
                onTap: () => _setPhoto(context, 'assets/profile.jpg'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('assets/profile2.jpg'),
                ),
                title: const Text('Alternate'),
                onTap: () => _setPhoto(context, 'assets/profile2.jpg'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setPhoto(BuildContext context, String path) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(ProfilePage.uid)
        .update({'photoURL': path});

    Navigator.pop(context);
  }

  void _openSkillsEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _EditSkillsSheet(),
    );
  }
}

/* =========================
   EDIT SKILLS SHEET
========================= */

class _EditSkillsSheet extends StatefulWidget {
  const _EditSkillsSheet();

  @override
  State<_EditSkillsSheet> createState() => _EditSkillsSheetState();
}

class _EditSkillsSheetState extends State<_EditSkillsSheet> {
  final List<String> allSkills = [
    'Barista',
    'Retail',
    'Customer Service',
    'Packing',
    'Cashier',
    'Events',
    'Usher',
  ];

  final Set<String> selected = {};

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .doc(ProfilePage.uid)
        .get()
        .then((doc) {
      final skills = List<String>.from(doc['skills'] ?? []);
      setState(() {
        selected.addAll(skills.map((e) => e.trim()));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Edit Skills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: allSkills.map((skill) {
              return ChoiceChip(
                label: Text(skill),
                selected: selected.contains(skill),
                onSelected: (value) {
                  setState(() {
                    value ? selected.add(skill) : selected.remove(skill);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(ProfilePage.uid)
                    .update({'skills': selected.toList()});

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}