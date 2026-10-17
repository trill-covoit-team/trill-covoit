import 'package:flutter/material.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/features/auth/widgets/auth_error_messages.dart';

class AuthMessage extends StatelessWidget {
  const AuthMessage({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.s16),
        padding: const EdgeInsets.all(AppSpace.s16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color,
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Text(
                isError ? AuthErrorMessages.display(message) : message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
