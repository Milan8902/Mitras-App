// ignore_for_file: deprecated_member_use

import 'package:url_launcher/url_launcher.dart';

class MapsUtils {
  MapsUtils._();

  //latitude and longitude
  static Future<void> openMapWithPosition(
      double latitude, double longitude) async {
    // Use a direct Google Maps URL that works on both app and web
    final Uri mapsUri = Uri.parse(
        'https://maps.google.com/maps?q=$latitude,$longitude');

    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(
          mapsUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        // Fallback to web browser if app launch fails
        final Uri webUri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      throw "Error opening map: $e";
    }
  }

  //text address
  static Future<void> openMapWithAddress(String fullAddress) async {
    String query = Uri.encodeComponent(fullAddress);
    final Uri mapsUri = Uri.parse('https://maps.google.com/maps?q=$query');

    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(
          mapsUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        // Fallback to web browser if app launch fails
        final Uri webUri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$query');
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      throw "Error opening map: $e";
    }
  }
}
