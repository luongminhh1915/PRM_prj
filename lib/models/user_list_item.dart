class UserListItem {
  const UserListItem({
    required this.id,
    required this.fullname,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    required this.idCard,
  });

  final int id;
  final String fullname;
  final String username;
  final String email;
  final String role;
  final String status;
  final String idCard;

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    return UserListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullname: json['fullname'] as String? ?? '—',
      username: json['username'] as String? ?? '—',
      email: json['email'] as String? ?? '—',
      role: json['role'] as String? ?? json['role_name'] as String? ?? '—',
      status: json['status'] as String? ?? 'active',
      idCard: json['id_card'] as String? ?? json['idCard'] as String? ?? '—',
    );
  }
}
