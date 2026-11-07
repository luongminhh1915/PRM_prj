import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.fullName,
    required this.roleLabel,
    required this.currentTimeText,
    required this.isCompact,
    this.title,
    this.onProfileTap,
    this.timeChipColor = const Color(0xFF16A34A),
    this.avatarColor = const Color(0xFF1E293B),
  });

  final String fullName;
  final String roleLabel;
  final String currentTimeText;
  final bool isCompact;
  final String? title;
  final VoidCallback? onProfileTap;
  final Color timeChipColor;
  final Color avatarColor;

  String get _avatarLabel {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim()[0].toUpperCase();
    }
    return roleLabel[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final timeChip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: timeChipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        currentTimeText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    final avatar = Material(
      color: avatarColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onProfileTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              _avatarLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
                tooltip: 'Open menu',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: timeChip),
              ),
            ),
            const SizedBox(width: 8),
            avatar,
          ] else ...[
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const SizedBox.shrink(),
            const Spacer(),
            timeChip,
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fullName.isEmpty ? roleLabel : fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            avatar,
          ],
        ],
      ),
    );
  }
}
