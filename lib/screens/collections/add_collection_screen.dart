import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/constants/icon_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_save_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AddCollectionScreen extends StatefulWidget {
  const AddCollectionScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AddCollectionScreenState();
}

class _AddCollectionScreenState extends State<AddCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  IconData? _selectedIcon;
  bool isPublic = false;
  Language language = Language.spanish;
  // Get all IconData values from iconNameMap
  final List<IconData> icons = iconNameMap.values.toList();
  // State that holds possibly preset options to add to the collection?

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void createNewCollection() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final String collectionResult =
          await CollectionsService.createNewCollection(
            collection: Collection(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim() != ''
                  ? _descriptionController.text.trim()
                  : null,
              language: language,
              isPublic: isPublic,
              icon: _selectedIcon,
              createdAt: DateTime.now(),
              createdBy: userId,
            ),
          );
      print('collection added: $collectionResult');

      final bool saveResult = await CollectionsSaveService.createCollectionSave(
        userId: userId,
        collectionId: collectionResult,
      );
      print('CollectionSave: $saveResult');

      if (saveResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collection was successfully created!'),
              backgroundColor: AppColors.successColor,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        print('Something went wrong: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Collection'),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputContainer(
                  label: 'Title',
                  controller: _titleController,
                ),
                const SizedBox(height: 20),

                _buildInputContainer(
                  label: 'Description',
                  controller: _descriptionController,
                  maxLines: 5,
                  minLines: 2,
                  maxLength: 250,
                ),
                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Make it public?',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Switch(
                      value: isPublic,
                      onChanged: (bool value) {
                        setState(() {
                          isPublic = value;
                        });
                      },
                      activeTrackColor: AppColors.secondaryAccent,
                      activeColor: Colors.white,
                      
                    ),
                  ],
                ),

                // Icon selection
                _buildIconWrap(icons, (IconData icon) {
                  setState(() {
                    _selectedIcon = icon;
                  });
                }, _selectedIcon),
                const SizedBox(height: 26),

                // Create Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => createNewCollection(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryAccent,
                        disabledBackgroundColor: AppColors.disabledColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        'Create new Collection',
                        style: AppTextStyles.heading2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    int? minLines,
    int? maxLength,
    // required
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryAccent.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),

          // Input field
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          // Description
        ],
      ),
    );
  }

  Widget _buildIconWrap(
    List<IconData> icons,
    void Function(IconData) onSelect,
    IconData? selectedIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collection Icon',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: icons.map((icon) {
            final isSelected = icon == selectedIcon;
            return GestureDetector(
              onTap: () => onSelect(icon),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondaryAccent.withOpacity(0.8)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white70,
                  size: 42,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
