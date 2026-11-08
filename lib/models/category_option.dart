class CategoryOption {
  const CategoryOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}
