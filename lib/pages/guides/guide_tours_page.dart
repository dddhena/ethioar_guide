import 'package:flutter/material.dart';
import '../../models/guide.dart';
import '../../models/landmark.dart';
import '../../models/tour_package.dart';
import '../../services/firestore_service.dart';
import '../../services/guide_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class GuideToursPage extends StatelessWidget {
  final Guide guide;

  const GuideToursPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final service = GuideService();
    return AppScaffold(
      title: 'My Tours',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add Tour',
          onPressed: () => _showTourEditor(context, service),
        ),
      ],
      body: StreamBuilder<List<TourPackage>>(
        stream: service.getToursStream(guide.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No tour services listed yet.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Tour'),
                    onPressed: () => _showTourEditor(context, service),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${t.durationLabel} • ${t.formattedPrice} • ${t.language}\n${t.attractionsLabel}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showTourEditor(context, service, existing: t),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () async {
                          await service.deleteTour(t.id);
                          if (context.mounted) SnackbarHelper.show(context, 'Tour deleted');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showTourEditor(BuildContext context, GuideService service, {TourPackage? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final durationCtrl = TextEditingController(text: existing != null ? existing.durationHours.toString() : '5');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : guide.price.toStringAsFixed(0));
    final languageCtrl = TextEditingController(text: existing?.language ?? 'English');
    String tourType = existing?.tourType ?? 'cultural-heritage';
    final selected = List<String>.from(existing?.attractions ?? []);
    bool saving = false;

    final landmarks = await FirestoreService().fetchLandmarks();

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Tour' : 'Edit Tour'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tour name')),
                      const SizedBox(height: 8),
                      TextFormField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(tourType),
                        initialValue: tourType,
                        decoration: const InputDecoration(labelText: 'Tour type'),
                        items: const [
                          DropdownMenuItem(value: 'cultural-heritage', child: Text('Cultural heritage')),
                          DropdownMenuItem(value: 'nature', child: Text('Nature & trekking')),
                          DropdownMenuItem(value: 'city', child: Text('City tour')),
                          DropdownMenuItem(value: 'religious', child: Text('Religious / pilgrimage')),
                        ],
                        onChanged: (v) => setDialog(() => tourType = v ?? tourType),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Duration (hours)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Price (ETB)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(controller: languageCtrl, decoration: const InputDecoration(labelText: 'Language')),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Attractions', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final Landmark lm in landmarks)
                            FilterChip(
                              label: Text(lm.name),
                              selected: selected.contains(lm.name),
                              onSelected: (on) {
                                setDialog(() {
                                  if (on) {
                                    selected.add(lm.name);
                                  } else {
                                    selected.remove(lm.name);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final extra = TextEditingController();
                          final name = await showDialog<String>(
                            context: ctx,
                            builder: (c2) => AlertDialog(
                              title: const Text('Add attraction name'),
                              content: TextField(controller: extra, decoration: const InputDecoration(hintText: 'e.g. Bete Giyorgis')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c2), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(c2, extra.text.trim()), child: const Text('Add')),
                              ],
                            ),
                          );
                          if (name != null && name.isNotEmpty) {
                            setDialog(() => selected.add(name));
                          }
                        },
                        child: const Text('+ Custom attraction'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          setDialog(() => saving = true);
                          final tour = TourPackage(
                            id: existing?.id ?? '',
                            guideId: guide.id,
                            name: nameCtrl.text.trim(),
                            tourType: tourType,
                            description: descCtrl.text.trim(),
                            durationHours: double.tryParse(durationCtrl.text) ?? 5,
                            price: double.tryParse(priceCtrl.text) ?? 0,
                            attractions: selected,
                            language: languageCtrl.text.trim().isEmpty ? 'English' : languageCtrl.text.trim(),
                          );
                          try {
                            if (existing == null) {
                              await service.addTour(tour);
                            } else {
                              await service.updateTour(tour);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              SnackbarHelper.show(context, existing == null ? 'Tour added' : 'Tour updated');
                            }
                          } catch (e) {
                            setDialog(() => saving = false);
                            if (context.mounted) SnackbarHelper.show(context, 'Error: $e');
                          }
                        },
                  child: Text(existing == null ? 'Add Tour' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
