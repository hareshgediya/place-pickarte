import 'package:place_pickarte/src/services/google/core.dart';
import 'package:place_pickarte/src/services/google/geocoding.dart';
import 'package:place_pickarte/src/services/google/places.dart';

import 'platform_places_client_io.dart'
    if (dart.library.html) 'platform_places_client_web.dart'
    if (dart.library.js_interop) 'platform_places_client_web.dart'
    as impl;

/// Cross-platform Places + Geocoding client.
///
/// On mobile this uses the Google Maps Web Service REST APIs.
/// On web it uses the Maps JavaScript API (Places + Geocoder) to avoid CORS.
abstract class PlatformPlacesClient {
  factory PlatformPlacesClient({
    required String apiKey,
    Map<String, String>? apiHeaders,
    GoogleMapsGeocoding? geocoding,
  }) {
    return impl.createPlatformPlacesClient(
      apiKey: apiKey,
      apiHeaders: apiHeaders,
      geocoding: geocoding,
    );
  }

  Future<PlacesAutocompleteResponse> autocomplete(
    String input, {
    String? sessionToken,
    num? offset,
    Location? origin,
    Location? location,
    num? radius,
    String? language,
    List<String> types = const [],
    List<Component> components = const [],
    bool strictbounds = false,
    String? region,
  });

  Future<PlaceDetails> getDetailsByPlaceId(String placeId);

  Future<GeocodingResponse> searchByLocation(Location location);
}
