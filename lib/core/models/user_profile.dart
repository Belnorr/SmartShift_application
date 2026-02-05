enum UserRole { employer, worker }

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<String> skills;
  final int points;
  final int reliability; // 0..100
  final int shiftsCompleted;
  final int latePenalties;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.skills,
    required this.points,
    required this.reliability,
    required this.shiftsCompleted,
    required this.latePenalties,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    UserRole? role,
    List<String>? skills,
    int? points,
    int? reliability,
    int? shiftsCompleted,
    int? latePenalties,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      points: points ?? this.points,
      reliability: reliability ?? this.reliability,
      shiftsCompleted: shiftsCompleted ?? this.shiftsCompleted,
      latePenalties: latePenalties ?? this.latePenalties,
    );
  }
}
