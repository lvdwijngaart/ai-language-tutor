import 'package:ai_lang_tutor_v2/constants/app_constants.dart';
import 'package:ai_lang_tutor_v2/constants/icon_constants.dart';
import 'package:ai_lang_tutor_v2/models/database/collection.dart';
import 'package:ai_lang_tutor_v2/models/enums/app_enums.dart';
import 'package:ai_lang_tutor_v2/providers/language_provider.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_save_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase/collections/collections_service.dart';
import 'package:ai_lang_tutor_v2/services/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  Language _language = Language.spanish; // TODO: Still have to decide how language will be worked into the whole app

  // Get all IconData values from iconNameMap
  final List<IconData> icons = iconNameMap.values.toList();

  bool _isLoading = false;

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

    setState(() {
      _isLoading = true;
    });

    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final userId = supabase.auth.currentUser!.id;
      final Collection savedCollection = await CollectionsService.createNewCollection(
        collection: Collection(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim() != ''
              ? _descriptionController.text.trim()
              : null,
          language: _language,
          isPublic: isPublic,
          icon: _selectedIcon,
          createdAt: DateTime.now(),
          createdBy: userId,
        ), 
        userIdForSave: supabase.auth.currentUser!.id,
      );
      print('collection added: $savedCollection');

      final sentenceScreenResult = await context.push(
        '/collections/${savedCollection.id}/suggested-sentences', 
        extra: savedCollection
      );

      if (sentenceScreenResult != null && 
          sentenceScreenResult is Map<String, dynamic> && 
          sentenceScreenResult['status'] == 'completed') {
        
        if (mounted) {
          context.pop({
            'status': 'completed', 
            'collection': sentenceScreenResult['collection'] ?? savedCollection, 
            'sentences': sentenceScreenResult['sentences'] ?? []
          });
        }
      } else {
        // TODO: Possibly delete the collection? 
        // await CollectionsService.deleteCollection(savedCollection.id);
        // if (mounted) {
        //   context.pop({'status': 'cancelled'});
        // }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating collection: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        print('Error creating collection: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: true, // Add this line
        title: Text(
          'Create Collection',
          style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
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

                // Language display
                _buildLanguageDisplay(),
                const SizedBox(height: 30),

                // Title input
                _buildInputContainer(
                  label: 'Title',
                  placeholder: 'e.g. Travel Phrases',
                  controller: _titleController,
                  isRequired: true,
                ),
                const SizedBox(height: 30),

                // Description input
                _buildInputContainer(
                  label: 'Description',
                  placeholder: 'A short summary of what\'s in this collection',
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
                    // horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Public Collection',
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 17,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          Text(
                            'Visible to other users', 
                            style: TextStyle(
                              color: Colors.white70, 
                              fontSize: 14
                            ),
                          )
                        ],
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Create new Collection',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontSize: 20
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

  Widget _buildLanguageDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12), 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Language', 
            style: TextStyle(
              color: Colors.white70, 
              fontSize: 17, 
              fontWeight: FontWeight.w500
            ),
          ), 

          Row(
            children: [
              Text(
                _language.flagEmoji, 
                style: TextStyle(
                  fontSize: 20, 
                ),
              ),
              const SizedBox(width: 8),

              Text(
                _language.displayName, 
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 17, 
                  fontWeight: FontWeight.w600
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInputContainer({
    required String label,
    required TextEditingController controller,
    required bool isRequired,
    String? placeholder,
    int maxLines = 1,
    int? minLines,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label + (isRequired ? '' : ' (Optional)'),
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        // Input field
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: placeholder, 
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        )
      ],
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
          'Choose an icon',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,            
          ),
          itemCount: icons.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final icon = icons[index];
            return _buildIconButton(icon, onSelect, icon == selectedIcon);
          },
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, void Function(IconData) onSelect, bool isSelected) {
    return GestureDetector(
      onTap: () => onSelect(icon),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryAccent.withOpacity(0.9)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.white
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
          size: 32,
        ),
      ),
    );
  }
}
