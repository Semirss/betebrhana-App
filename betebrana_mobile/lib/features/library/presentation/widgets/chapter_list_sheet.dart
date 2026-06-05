import 'package:flutter/material.dart';

class Chapter {
  final String title;
  final int index;
  final double scrollOffset; // For tracking position in the document

  const Chapter({
    required this.title,
    required this.index,
    required this.scrollOffset,
  });
}

class ChapterListSheet extends StatelessWidget {
  final List<Chapter> chapters;
  final Function(Chapter) onChapterSelected;

  const ChapterListSheet({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chapters',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          Expanded(
            child: chapters.isEmpty
                ? Center(
                    child: Text(
                      'No chapters found',
                      style: TextStyle(color: secondaryTextColor, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chapters.length,
                    separatorBuilder: (context, index) => Divider(
                      color: isDark ? Colors.white12 : Colors.black12,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return ListTile(
                        title: Text(
                          chapter.title,
                          style: TextStyle(color: textColor),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onChapterSelected(chapter);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

void showChapterListSheet(
  BuildContext context, {
  required List<Chapter> chapters,
  required Function(Chapter) onChapterSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ChapterListSheet(
      chapters: chapters,
      onChapterSelected: onChapterSelected,
    ),
  );
}
