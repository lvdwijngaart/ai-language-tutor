import 'package:flutter/material.dart';
import 'package:ai_lang_tutor_v2/constants/app_constants.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.icon,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon (if provided)
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (confirmColor ?? AppColors.electricBlue).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon!,
                  color: confirmColor ?? AppColors.electricBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      onCancel?.call();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor ?? AppColors.electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Convenience method to show the confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          confirmColor: confirmColor,
          icon: icon,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
    );
  }
}

/// Specialized confirmation dialogs for common actions
class DeleteConfirmationDialog extends ConfirmationDialog {
  const DeleteConfirmationDialog({
    Key? key,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) : super(
          key: key,
          title: title,
          message: message,
          confirmText: 'Delete',
          cancelText: 'Cancel',
          confirmColor: Colors.red,
          icon: Icons.delete_outline,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          title: title,
          message: message,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
    );
  }
}

class SaveConfirmationDialog extends ConfirmationDialog {
  const SaveConfirmationDialog({
    Key? key,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) : super(
          key: key,
          title: title,
          message: message,
          confirmText: 'Save',
          cancelText: 'Cancel',
          confirmColor: AppColors.secondaryAccent,
          icon: Icons.bookmark_add_outlined,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SaveConfirmationDialog(
          title: title,
          message: message,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
    );
  }
}


class UnsaveConfirmationDialog extends ConfirmationDialog {
  const UnsaveConfirmationDialog({
    Key? key,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) : super(
          key: key,
          title: title,
          message: message,
          confirmText: 'Remove',
          cancelText: 'Cancel',
          confirmColor: Colors.orange,
          icon: Icons.bookmark_remove_outlined,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UnsaveConfirmationDialog(
          title: title,
          message: message,
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
    );
  }
}
