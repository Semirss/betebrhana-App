import 'package:flutter/material.dart';

class ReaderHeader extends StatelessWidget {
  final String title;
  final String pageInfo;
  final bool isSearching;
  final bool isLockEnabled;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onBackPressed;
  final VoidCallback onToggleSearch;
  final VoidCallback onClearSearch;
  final Function(String) onSearchSubmitted;
  final VoidCallback onToggleLock;
  final VoidCallback onSearchNext;
  final GlobalKey? searchKey;
  final GlobalKey? lockKey;
  final GlobalKey? pageInfoKey;

  const ReaderHeader({
    super.key,
    required this.title,
    required this.pageInfo,
    required this.isSearching,
    required this.isLockEnabled,
    required this.searchController,
    required this.searchFocusNode,
    required this.onBackPressed,
    required this.onToggleSearch,
    required this.onClearSearch,
    required this.onSearchSubmitted,
    required this.onToggleLock,
    required this.onSearchNext,
    this.searchKey,
    this.lockKey,
    this.pageInfoKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = const Color(0xFFFF7A3B);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textColor),
                onPressed: onBackPressed,
                tooltip: 'Back',
              ),
              if (isSearching)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                                color: secondaryTextColor, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onSubmitted: onSearchSubmitted,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: textColor, size: 20),
                        onPressed: onSearchNext,
                        tooltip: 'Find Next',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor, size: 20),
                        onPressed: onClearSearch,
                        tooltip: 'Close Search',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                )
              else ...[
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: searchKey,
                  icon: Icon(Icons.search_rounded, color: textColor, size: 22),
                  onPressed: onToggleSearch,
                  tooltip: 'Search',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  key: lockKey,
                  icon: Icon(
                    isLockEnabled
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    color: isLockEnabled ? accentColor : textColor,
                    size: 20,
                  ),
                  onPressed: onToggleLock,
                  tooltip: 'Lock Settings',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Container(
                  key: pageInfoKey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pageInfo,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
