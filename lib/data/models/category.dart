class Category {
  const Category({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'description': description,
      };

  Map<String, dynamic> toUpdateMap() => toInsertMap();
}
