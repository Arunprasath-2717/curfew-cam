import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class InputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final Widget? trailing;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const InputField({
    super.key,
    required this.label,
    required this.hintText,
    this.icon,
    this.isPassword = false,
    this.controller,
    this.trailing,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: AppTextStyles.bodyMain,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)) : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
