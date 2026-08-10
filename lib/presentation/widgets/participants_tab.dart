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
    final l10n = AppLocalizations.of(context)!;

    return personsAsync.when(
      data: (persons) {
        return Column(
          children: [
            Expanded(
              child: persons.isEmpty
                  ? Center(child: Text(l10n.noParticipants))
                  : ListView.builder(
                      itemCount: persons.length,
                      itemBuilder: (context, index) {
                        final person = persons[index];
                        return ListTile(
                          title: Text(person.displayName),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => ref
                                .read(personsProvider(tripId).notifier)
                                .deletePerson(person.id),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _addParticipant(context, ref, l10n),
                icon: const Icon(Icons.person_add),
                label: Text(l10n.addParticipant),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _addParticipant(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addParticipant),
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
              final person = Person(
                id: const Uuid().v4(),
                displayName: controller.text.trim(),
                tripId: tripId,
              );
              ref.read(personsProvider(tripId).notifier).addPerson(person);
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
