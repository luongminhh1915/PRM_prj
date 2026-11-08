class RoleOption {
  const RoleOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory RoleOption.fromJson(Map<String, dynamic> json) {
    return RoleOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '—',
    );
  }
}
