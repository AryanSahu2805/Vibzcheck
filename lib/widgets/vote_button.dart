import 'package:flutter/material.dart';
import '../config/theme.dart';

class VoteButton extends StatelessWidget {
  final bool isUpvote;
  final bool isActive;
  final VoidCallback? onPressed;

  const VoteButton({
    Key? key,
    required this.isUpvote,
    this.isActive = false,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isUpvote ? Icons.arrow_upward : Icons.arrow_downward,
        color: isActive
            ? (isUpvote ? AppTheme.successColor : AppTheme.errorColor)
            : AppTheme.textSecondary,
      ),
      onPressed: onPressed,
    );
  }
}