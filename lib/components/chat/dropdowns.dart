

import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

class TutorChatDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final List<Widget> Function(BuildContext)? itemBuilder;
  final String? hint;
  final Color accentColor;
  final double fontSize;
  final Icon? icon;

  const TutorChatDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
    this.hint,
    this.accentColor = AppColors.electricBlue,
    this.fontSize = AppSpacing.medium,
    this.icon, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.only(right: AppSpacing.small), 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.2), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: accentColor, width: 1)
      ), 
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: icon,
          dropdownColor: AppColors.cardBackground,
          style: TextStyle(color: accentColor, fontSize: fontSize),
          selectedItemBuilder: itemBuilder,
          items: items, 
          onChanged: onChanged, 
          isDense: true,
          iconSize: 20,
          isExpanded: true,
        )
      ),
    );
  }
}