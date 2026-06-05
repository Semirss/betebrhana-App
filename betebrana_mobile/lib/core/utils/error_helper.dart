import 'package:flutter/material.dart';

class ErrorHelper {
  static String getFriendlyMessage(dynamic e, [String fallback = 'An unexpected error occurred.']) {
    final msg = e.toString().replaceAll('Exception: ', '').trim();
    if (msg.contains('SocketException') || msg.contains('XMLHttpRequest') || msg.contains('Failed host lookup')) {
      return 'Please check your internet connection and try again.';
    }
    if (msg.contains('TimeoutException')) {
      return 'The request timed out. Please try again later.';
    }
    if (msg.length > 80 || msg.contains('Null check') || msg.contains('type \'') || msg.contains('NoSuchMethodError')) {
      return fallback;
    }
    return msg.isNotEmpty ? msg : fallback;
  }
}
