import 'package:flutter/material.dart';

/// A lightweight, themeable dropdown that uses a rounded container and
/// hides the native underline. Designed to replace the older, plain
/// `DropdownButton` instances throughout the app with a more modern look.
///
/// Example usage:
///
/// ```dart
/// ModernDropdown<int>(
///   value: selectedMonthIndex,
///   items: List.generate(monthNames.length, (i) {
///     return DropdownMenuItem(value: i, child: Text(monthNames[i]));
///   }),
///   hint: Text(l10n.selectMonth),
///   onChanged: (v) { setState(() => selectedMonthIndex = v); },
/// )
/// ```
class ModernDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? icon;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;
  final Color borderColor;
  final bool isExpanded;

  const ModernDropdown({
    Key? key,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.backgroundColor,
    this.borderRadius = 10,
    this.borderColor = const Color(0xFFDDDDDD),
    this.isExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: padding,
      decoration: BoxDecoration(
        // color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: hint,
          icon: icon ?? const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          isExpanded: isExpanded,
        ),
      ),
    );
  }
}
