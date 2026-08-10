class Person {
  final String id;
  final String displayName;
  final String tripId;

  const Person({
    required this.id,
    required this.displayName,
    required this.tripId,
  });

  Person copyWith({String? displayName}) => Person(
    id: id,
    displayName: displayName ?? this.displayName,
    tripId: tripId,
  );

  @override
  bool operator ==(Object other) => other is Person && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Person($displayName)';
}
