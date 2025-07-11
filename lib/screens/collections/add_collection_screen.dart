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
  IconData? _selectedIcon = iconNameMap.values.first;
  bool isPublic = false;
  Language language = Language
      .spanish; // TODO: Still have to decide how language will be worked into the whole app

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
          context.go('/collections/create/suggestions');
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
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        title: Text(
          'Create New Collection',
          style: TextStyle(
            color: AppColors.secondaryAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios, color: AppColors.secondaryAccent),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title input
                _buildInputContainer(
                  label: 'Title',
                  controller: _titleController,
                  isRequired: true,
                ),
                const SizedBox(height: 20),

                // Description input
                _buildInputContainer(
                  label: 'Description',
                  controller: _descriptionController,
                  isRequired: false,
                  maxLines: 5,
                  minLines: 2,
                  maxLength: 250,
                ),
                const SizedBox(height: 26),

                // Public toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        activeTrackColor: AppColors.secondaryAccent.withOpacity(
                          0.5,
                        ),
                        activeColor: AppColors.secondaryAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Icon selection
                _buildIconWrap(icons, (IconData icon) {
                  setState(() {
                    _selectedIcon = icon;
                  });
                }, _selectedIcon),
                const SizedBox(height: 26),

                // Create Button
                SizedBox(
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
                      elevation: 4,
                    ),
                    child: Text(
                      'Create new Collection',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
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
    required bool isRequired,
    int maxLines = 1,
    int? minLines,
    int? maxLength,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryAccent.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryAccent.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return '$label is required';
              }
              return null;
            },
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.secondaryAccent.withOpacity(0.5),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.secondaryAccent),
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterStyle: TextStyle(color: Colors.white54),
            ),
          ),
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
            color: AppColors.secondaryAccent,
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
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondaryAccent.withOpacity(0.9)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondaryAccent
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.secondaryAccent.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
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
