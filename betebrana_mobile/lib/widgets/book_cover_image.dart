import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BookCoverImage extends StatelessWidget {
  final String? path;
  final double borderRadius;

  const BookCoverImage({super.key, this.path, this.borderRadius = 0});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          color: Colors.grey[300],
          child: const Icon(Icons.book, color: Colors.grey),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: AppConfig.resolveUrl(path),
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) =>
            Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
  }
}
