import 'package:flutter/material.dart';

class ReaderBottomControls extends StatelessWidget {
  final bool isBookmarked;
  final bool isAutoScrolling;
  final bool isOrientationLandscape;
  final VoidCallback onShowChapterList;
  final VoidCallback onToggleBookmark;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onToggleOrientation;
  final VoidCallback onShowDisplaySettings;

  const ReaderBottomControls({
    super.key,
    required this.isBookmarked,
    required this.isAutoScrolling,
    required this.isOrientationLandscape,
    required this.onShowChapterList,
    required this.onToggleBookmark,
    required this.onToggleAutoScroll,
    required this.onToggleOrientation,
    required this.onShowDisplaySettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor = const Color(0xFFFF7A3B);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: textColor.withOpacity(0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isOrientationLandscape ? 40 : 20,
            12,
            isOrientationLandscape ? 40 : 20,
            12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ControlButton(
                icon: Icons.format_list_bulleted_rounded,
                color: textColor,
                onTap: onShowChapterList,
                tooltip: 'Chapters',
              ),
              _ControlButton(
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isBookmarked ? accentColor : textColor,
                onTap: onToggleBookmark,
                tooltip: 'Bookmark',
              ),
              _ControlButton(
                icon: isAutoScrolling
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                color: isAutoScrolling ? accentColor : textColor,
                onTap: onToggleAutoScroll,
                tooltip: 'Auto-Scroll',
              ),
              _ControlButton(
                icon: Icons.screen_rotation_rounded,
                color: textColor,
                onTap: onToggleOrientation,
                tooltip: 'Rotate Screen',
              ),
              _ControlButton(
                icon: Icons.text_fields_rounded,
                color: textColor,
                onTap: onShowDisplaySettings,
                tooltip: 'Text Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 24),
      onPressed: onTap,
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}
