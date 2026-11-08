class CategoryListItem {
  const CategoryListItem({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
  });

  final int id;
  final String name;
  final String status;
  final String? createdAt;

  factory CategoryListItem.fromJson(Map<String, dynamic> json) {
    return CategoryListItem(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

