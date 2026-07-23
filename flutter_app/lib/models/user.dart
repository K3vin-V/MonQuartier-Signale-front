class AppUser {
  final String id;
  final String email;
  final String role; // 'user' | 'moderateur' | 'super_admin'

  AppUser({required this.id, required this.email, required this.role});

  bool get isAdmin => role == 'super_admin';

  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(id: j['id'], email: j['email'], role: j['role'] ?? 'user');
}
