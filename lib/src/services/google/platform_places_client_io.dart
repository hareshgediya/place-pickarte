import 'package:place_pickarte/src/services/google/core.dart';
import 'package:place_pickarte/src/services/google/geocoding.dart';
import 'package:place_pickarte/src/services/google/places.dart';
import 'package:place_pickarte/src/services/google/platform_places_client.dart';

PlatformPlacesClient createPlatformPlacesClient({
  required String apiKey,
  Map<String, String>? apiHeaders,
  GoogleMapsGeocoding? geocoding,
}) {
  return _IoPlatformPlacesClient(apiKey: apiKey, apiHeaders: apiHeaders, geocoding: geocoding);
}

class _IoPlatformPlacesClient implements PlatformPlacesClient {
  _IoPlatformPlacesClient({
    required String apiKey,
    Map<String, String>? apiHeaders,
    GoogleMapsGeocoding? geocoding,
  }) : _places = GoogleMapsPlaces(apiKey: apiKey, apiHeaders: apiHeaders),
       _geocoding = geocoding ?? GoogleMapsGeocoding(apiKey: apiKey, apiHeaders: apiHeaders);

  final GoogleMapsPlaces _places;
  final GoogleMapsGeocoding _geocoding;

  @override
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
  }) {
    return _places.autocomplete(
      input,
      sessionToken: sessionToken,
      offset: offset,
      origin: origin,
      location: location,
      radius: radius,
      language: language,
      types: types,
      components: components,
      strictbounds: strictbounds,
      region: region,
    );
  }

  @override
  Future<PlaceDetails> getDetailsByPlaceId(String placeId) async {
    final response = await _places.getDetailsByPlaceId(placeId);
    return response.result;
  }

  @override
  Future<GeocodingResponse> searchByLocation(Location location) {
    return _geocoding.searchByLocation(location);
  }
}
