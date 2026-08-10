class SettlementGroup {
  final String id;
  final String name;
  final String tripId;
  final List<String> memberIds;

  const SettlementGroup({
    required this.id,
    required this.name,
    required this.tripId,
    required this.memberIds,
  });

  SettlementGroup copyWith({String? name, List<String>? memberIds}) =>
      SettlementGroup(
        id: id,
        name: name ?? this.name,
        tripId: tripId,
        memberIds: memberIds ?? this.memberIds,
      );

  @override
  bool operator ==(Object other) => other is SettlementGroup && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
