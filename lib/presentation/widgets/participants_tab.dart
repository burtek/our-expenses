import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/models.dart';
import '../providers/providers.dart';

class ParticipantsTab extends ConsumerWidget {
  final String tripId;
  const ParticipantsTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(personsProvider(tripId));
    final groupsAsync = ref.watch(settlementGroupsProvider(tripId));
    final l10n = AppLocalizations.of(context)!;

    return personsAsync.when(
      data: (persons) => groupsAsync.when(
        data: (groups) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.participants,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (persons.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(l10n.noParticipants),
              )
            else
              ...persons.map(
                (person) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(person.displayName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _editParticipant(context, ref, l10n, person),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => ref
                            .read(personsProvider(tripId).notifier)
                            .deletePerson(person.id),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _addParticipant(context, ref, l10n),
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addParticipant),
            ),
            const Divider(height: 32),
            Text(
              l10n.settlementGroups,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(l10n.noSettlementGroups),
              )
            else
              ...groups.map(
                (group) => Card(
                  child: ListTile(
                    title: Text(group.name),
                    subtitle: Text(
                      group.memberIds
                          .map(
                            (memberId) => persons
                                .where((person) => person.id == memberId)
                                .firstOrNull
                                ?.displayName,
                          )
                          .whereType<String>()
                          .join(', '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editGroup(
                            context,
                            ref,
                            l10n,
                            persons,
                            groups,
                            group,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref
                              .read(settlementGroupsProvider(tripId).notifier)
                              .deleteGroup(group.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            FilledButton.icon(
              onPressed: persons.isEmpty
                  ? null
                  : () => _addGroup(context, ref, l10n, persons, groups),
              icon: const Icon(Icons.group_add),
              label: Text(l10n.addGroup),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _addParticipant(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    _showParticipantDialog(context, ref, l10n);
  }

  void _editParticipant(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Person person,
  ) {
    _showParticipantDialog(context, ref, l10n, person: person);
  }

  void _showParticipantDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    Person? person,
  }) {
    final controller = TextEditingController();
    controller.text = person?.displayName ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          person == null ? l10n.addParticipant : l10n.renameParticipant,
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.participantName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              if (person == null) {
                final newPerson = Person(
                  id: const Uuid().v4(),
                  displayName: controller.text.trim(),
                  tripId: tripId,
                );
                ref
                    .read(personsProvider(tripId).notifier)
                    .addPerson(newPerson);
              } else {
                ref
                    .read(personsProvider(tripId).notifier)
                    .updatePerson(
                      person.copyWith(displayName: controller.text.trim()),
                    );
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _addGroup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Person> persons,
    List<SettlementGroup> groups,
  ) {
    _showGroupDialog(context, ref, l10n, persons, groups);
  }

  void _editGroup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Person> persons,
    List<SettlementGroup> groups,
    SettlementGroup group,
  ) {
    _showGroupDialog(context, ref, l10n, persons, groups, group: group);
  }

  void _showGroupDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Person> persons,
    List<SettlementGroup> groups, {
    SettlementGroup? group,
  }) {
    final controller = TextEditingController(text: group?.name ?? '');
    final selectedMembers = {...?group?.memberIds};
    final assignedGroupByPerson = <String, SettlementGroup>{};
    for (final existingGroup in groups) {
      if (existingGroup.id == group?.id) continue;
      for (final memberId in existingGroup.memberIds) {
        assignedGroupByPerson[memberId] = existingGroup;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(group == null ? l10n.addGroup : l10n.editGroup),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: l10n.groupName),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.members,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...persons.map((person) {
                    final assignedGroup = assignedGroupByPerson[person.id];
                    final disabled = assignedGroup != null;
                    return CheckboxListTile(
                      value: selectedMembers.contains(person.id),
                      onChanged: disabled
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  selectedMembers.add(person.id);
                                } else {
                                  selectedMembers.remove(person.id);
                                }
                              });
                            },
                      title: Text(person.displayName),
                      subtitle: disabled
                          ? Text(
                              '${l10n.participantAlreadyGrouped} '
                              '(${assignedGroup.name})',
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                if (selectedMembers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.selectAtLeastOneMember)),
                  );
                  return;
                }
                final nextGroup = SettlementGroup(
                  id: group?.id ?? const Uuid().v4(),
                  name: name,
                  tripId: tripId,
                  memberIds: selectedMembers.toList(),
                );
                if (group == null) {
                  ref
                      .read(settlementGroupsProvider(tripId).notifier)
                      .addGroup(nextGroup);
                } else {
                  ref
                      .read(settlementGroupsProvider(tripId).notifier)
                      .updateGroup(nextGroup);
                }
                Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
