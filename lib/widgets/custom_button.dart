import 'package:flutter/material.dart';
import '../config/theme.dart';

enum ButtonVariant { filled, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final Color? color;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.filled,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final buttonColor = color ?? AppTheme.primaryColor;

    Widget button;

    switch (variant) {
      case ButtonVariant.filled:
        button = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: _buildChild(),
        );
        break;
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: buttonColor, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: _buildChild(),
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: onPressed,
          child: _buildChild(),
        );
        break;
    }

    return button;
  }

  Widget _buildChild() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    return Text(text);
  }
}