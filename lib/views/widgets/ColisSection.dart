import 'package:flutter/material.dart';
import '../../../models/Order.dart';
import '../../models/PackageItem.dart';

class ColisSection extends StatefulWidget {
  final Function(List<PackageItem>) onPackageItemsChanged;

  const ColisSection({
    super.key,
    required this.onPackageItemsChanged
  });

  @override
  _ColisSectionState createState() => _ColisSectionState();
}

class _ColisSectionState extends State<ColisSection> {
  List<PackageItem> packageItems = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  void addPackageItem() {
    if (titleController.text.isEmpty ||
        weightController.text.isEmpty ||
        widthController.text.isEmpty ||
        heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final title = titleController.text;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final width = double.tryParse(widthController.text) ?? 0.0;
    final height = double.tryParse(heightController.text) ?? 0.0;

    setState(() {
      packageItems.add(PackageItem(
        title: title,
        weight: weight,
        width: width,
        height: height,
      ));
    });

    // Notify parent about the updated package items
    widget.onPackageItemsChanged(packageItems);

    // Clear the text fields after adding
    titleController.clear();
    weightController.clear();
    widthController.clear();
    heightController.clear();
  }

  void removePackageItem(int index) {
    setState(() {
      packageItems.removeAt(index);
    });
    widget.onPackageItemsChanged(packageItems);
  }

  @override
  void dispose() {
    titleController.dispose();
    weightController.dispose();
    widthController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Colis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: addPackageItem,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Ajouter un colis',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Titre',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Nom du colis',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Poids',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'kg',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Largeur',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: widthController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'cm',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hauteur',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: heightController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'cm',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (packageItems.isNotEmpty) ...[
              const Text(
                'Colis ajoutés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            ...packageItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    'Poids: ${item.weight} kg, Largeur: ${item.width} cm, Hauteur: ${item.height} cm',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => removePackageItem(index),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
