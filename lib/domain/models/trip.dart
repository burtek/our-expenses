class Trip {
  final String id;
  final String name;
  final String? description;
  final String currency;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.name,
    this.description,
    required this.currency,
    required this.createdAt,
  });

  Trip copyWith({String? name, String? description, String? currency}) => Trip(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        currency: currency ?? this.currency,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) => other is Trip && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
