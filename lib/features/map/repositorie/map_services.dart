import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';
import 'package:passenger_app/shared/models/route_info.dart';
import 'package:uuid/uuid.dart';

class MapServices {
  static const Uuid uuid = Uuid();

  //Get direction in text by passing Coordinates
  static Future<String?> getReadableAddress(
      double latitude, double longitude, String apiKey) async {
    final Logger logger = Logger();
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List;

          for (final result in results) {
            final types = result['types'] as List<dynamic>;

            // Check if result is of type "street_address" or "route"
            if (types.contains('street_address') || types.contains('route')) {
              final addressComponents = result['address_components'] as List;

              String? street;
              String? route;

              for (final component in addressComponents) {
                final componentTypes = component['types'] as List<dynamic>;

                if (componentTypes.contains('route')) {
                  route = component['long_name'];
                } else if (componentTypes.contains('street_address') ||
                    componentTypes.contains('street_number')) {
                  street = component['long_name'];
                }
              }

              // Return the formatted address
              if (street != null && route != null) {
                return '$street, $route';
              } else if (street != null) {
                return street;
              } else if (route != null) {
                return route;
              }
            }
          }
        }

        return 'No readable address found';
      } else {
        throw Exception(
            'Failed to fetch geocoding data: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error: $e');
      return 'Error fetching address';
    }
  }

  //Get autocomplete place by passing a word
  static Future<List<dynamic>> getAutocompletePlaces(
      String input, String apiKey) async {
    final Logger logger = Logger();
    logger.i("Calling Autocomplete Place API");

    try {
      String sessionToken = uuid.v4();
      String baseUrl =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';

      // URL con restricciones para Riobamba, Ecuador y resultados en español
      String url =
          '$baseUrl?input=$input&key=$apiKey&sessiontoken=$sessionToken'
          '&location=-1.6649,-78.6543&radius=5000'
          '&language=es&components=country:ec';

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body)['predictions'];
      } else {
        logger.i(
            "Error getting autocompleting data: Statuscode ${response.statusCode}");
        return [];
      }
    } catch (e) {
      logger.i("Error while autocompleting direction search: $e");
      return [];
    }
  }

  /// Fetches the coordinates (LatLng) for a given place_id
  static Future<LatLng?> getCoordinatesByPlaceId(
      String placeId, String apiKey) async {
    final Logger logger = Logger();
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];

        final latitude = location['lat'];
        final longitude = location['lng'];

        return LatLng(latitude, longitude); // Return as LatLng
      } else {
        logger.e('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Error fetching coordinates: $e');
      return null;
    }
  }

  //It returns a route as polylines (it is use to update polyline in Porvider)
  static Future<RouteInfo?> getRoutePolylinePoints(
      LatLng start, LatLng end, String apiKey) async {
    final Logger logger = Logger();

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> routePoints = [];
    try {
      try {
        PolylineResult result = await polylinePoints
            .getRouteBetweenCoordinates(
              googleApiKey: apiKey,
              request: PolylineRequest(
                  origin: PointLatLng(start.latitude, start.longitude),
                  destination: PointLatLng(end.latitude, end.longitude),
                  mode: TravelMode.driving),
            )
            .timeout(const Duration(seconds: 10));
        if (result.points.isNotEmpty) {
          result.points.forEach((PointLatLng point) {
            routePoints.add(LatLng(point.latitude, point.longitude));
          });
        }
        logger.i(
            "Result getting route: ${result.durationTexts} type: ${result.durationTexts![0]}");
        return RouteInfo(
          distance: "",
          duration:
              result.durationTexts != null ? result.durationTexts![0] : "",
          polylinePoints: routePoints,
        );
      } on TimeoutException catch (e) {
        logger.e("Timeout occurred: $e");
        return null;
      } on SocketException catch (e) {
        logger.e("Network issue: $e");
        return null;
      } catch (e) {
        logger.e("Unknown error: $e");
        return null;
      }
    } catch (e) {
      logger.e('Error fetching route: $e');
      return null;
    }
  }
}
