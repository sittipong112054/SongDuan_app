import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.role,
    required this.image,
    this.baseUrl,
    this.onMorePressed,
  });

  final String name;
  final String role;
  final String image;
  final String? baseUrl;
  final VoidCallback? onMorePressed;

  static const _textDark = Color(0xFF2F2F2F);

  ImageProvider _resolveImageProvider() {
    final s = image.trim();

    // 2) Relative path จากเซิร์ฟเวอร์ เช่น /uploads/avatars/xxx.jpg
    if (s.startsWith('/')) {
      final b = (baseUrl ?? '').trimRight();
      if (b.isNotEmpty) {
        return NetworkImage('$b$s');
      }
      // ไม่มี baseUrl ก็ fallback เป็น Asset เพื่อไม่ให้แครช
      return const AssetImage('assets/images/default_avatar.png');
    }

    return AssetImage(s);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _resolveImageProvider();

    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: provider,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            Text(
              role,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                color: Colors.black.withOpacity(0.45),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: onMorePressed,
          icon: const Icon(Icons.more_vert_rounded),
          color: Colors.black54,
        ),
      ],
    );
  }
}
