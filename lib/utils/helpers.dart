import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  // Show toast message
  static void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? AppConstants.errorColor : AppConstants.secondaryColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Show error dialog
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Hide dialog
  static void hideDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Format date
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  // Format time
  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat(AppConstants.timeFormat).format(dt);
  }

  // Format date time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  // Parse date
  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Get role display name
  static String getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleDoctor:
        return 'Doctor';
      case AppConstants.rolePatient:
        return 'Patient';
      case AppConstants.roleLab:
        return 'Lab';
      default:
        return 'User';
    }
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusScheduled:
        return Colors.orange;
      case AppConstants.statusConfirmed:
        return Colors.blue;
      case AppConstants.statusCompleted:
        return AppConstants.secondaryColor;
      case AppConstants.statusCancelled:
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }

  // Format currency
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Get image URL
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    // If path is already a full URL, return it
    if (path.startsWith('http')) return path;
    // Otherwise, prepend base URL
    return 'http://10.0.2.2:8000$path';
  }
}
