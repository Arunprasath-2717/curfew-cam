import 'package:flutter/material.dart';
import '../providers/auth_service.dart';

/// Resolves a relative avatar path (e.g. "/media/avatars/foo.jpg") or an
/// already-absolute URL to a full URL usable by NetworkImage.
/// Falls back to null if the value is blank.
String? resolveAvatarUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  // Relative path from Django — strip /api/v1 from AuthService.baseUrl
  final root = AuthService.baseUrl.replaceAll(RegExp(r'/api/v[0-9]+$'), '');
  return '$root$raw';
}

/// Displays a circular avatar.
///
/// Shows a [NetworkImage] when [avatarUrl] resolves to a valid URL;
/// falls back to a circle with [initials] on the first character.
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const AvatarWidget({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.radius = 32,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).primaryColor;
    final fg = textColor ?? Theme.of(context).scaffoldBackgroundColor;
    final resolved = resolveAvatarUrl(avatarUrl);

    if (resolved != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: NetworkImage(resolved),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initials.isNotEmpty ? initials[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
