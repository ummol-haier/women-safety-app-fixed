import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  static Future<String?> getCurrentLocation() async {
    var status = await Permission.location.request();
    if (!status.isGranted) return null;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String locationLink =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    return locationLink;
  }

  static getCurrentLocationLink() {}
}
