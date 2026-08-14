import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:place_pickarte/src/services/google/core.dart';
import 'package:place_pickarte/src/services/google/geocoding.dart';
import 'package:place_pickarte/src/services/google/places.dart';
import 'package:place_pickarte/src/services/google/platform_places_client.dart';

PlatformPlacesClient createPlatformPlacesClient({
  required String apiKey,
  Map<String, String>? apiHeaders,
  GoogleMapsGeocoding? geocoding,
}) {
  // REST Places/Geocoding are CORS-blocked in browsers; use Maps JS APIs.
  return _WebPlatformPlacesClient();
}

@JS('google.maps.places.AutocompleteService')
extension type _AutocompleteService._(JSObject _) implements JSObject {
  external _AutocompleteService();

  @JS('getPlacePredictions')
  external JSPromise<_AutocompleteResponse> _getPlacePredictions(JSObject request);

  Future<_AutocompleteResponse> getPlacePredictions(JSObject request) =>
      _getPlacePredictions(request).toDart;
}

@JS('google.maps.Geocoder')
extension type _Geocoder._(JSObject _) implements JSObject {
  external _Geocoder();

  @JS('geocode')
  external JSPromise<_GeocoderResponse> _geocode(JSObject request);

  Future<_GeocoderResponse> geocode(JSObject request) => _geocode(request).toDart;
}

@JS('google.maps.LatLng')
extension type _LatLng._(JSObject _) implements JSObject {
  external _LatLng(num lat, num lng);

  external num lat();
  external num lng();
}

extension type _AutocompleteResponse._(JSObject _) implements JSObject {
  external JSArray<_JsPrediction> get predictions;
}

extension type _GeocoderResponse._(JSObject _) implements JSObject {
  external JSArray<_JsGeocoderResult> get results;
}

extension type _JsPrediction._(JSObject _) implements JSObject {
  external String get description;
  @JS('place_id')
  external String get placeId;
  @JS('matched_substrings')
  external JSArray<_JsMatchedSubstring>? get matchedSubstrings;
}

extension type _JsMatchedSubstring._(JSObject _) implements JSObject {
  external num get offset;
  external num get length;
}

extension type _JsGeocoderResult._(JSObject _) implements JSObject {
  @JS('formatted_address')
  external String? get formattedAddress;
  @JS('place_id')
  external String get placeId;
  external _JsGeometry get geometry;
  external JSArray<JSString>? get types;
}

extension type _JsGeometry._(JSObject _) implements JSObject {
  external _LatLng get location;
}

class _WebPlatformPlacesClient implements PlatformPlacesClient {
  final _AutocompleteService _autocompleteService = _AutocompleteService();
  final _Geocoder _geocoder = _Geocoder();

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
  }) async {
    final request = JSObject();
    request['input'] = input.toJS;
    if (sessionToken != null) request['sessionToken'] = sessionToken.toJS;
    if (offset != null) request['offset'] = offset.toJS;
    if (language != null) request['language'] = language.toJS;
    if (region != null) request['region'] = region.toJS;
    if (types.isNotEmpty) {
      request['types'] = types.map((t) => t.toJS).toList().toJS;
    }
    if (location != null) {
      request['location'] = _LatLng(location.lat, location.lng);
    }
    if (radius != null) request['radius'] = radius.toJS;
    if (origin != null) {
      request['origin'] = _LatLng(origin.lat, origin.lng);
    }
    if (strictbounds) request['strictBounds'] = true.toJS;

    final countries = components
        .where((c) => c.component == Component.country)
        .map((c) => c.value)
        .toList();
    if (countries.isNotEmpty) {
      final restrictions = JSObject();
      restrictions['country'] = countries.length == 1
          ? countries.first.toJS
          : countries.map((c) => c.toJS).toList().toJS;
      request['componentRestrictions'] = restrictions;
    }

    try {
      final response = await _autocompleteService.getPlacePredictions(request);
      final list = <Prediction>[];
      for (final item in response.predictions.toDart) {
        final matched = <MatchedSubstring>[];
        for (final m in item.matchedSubstrings?.toDart ?? const []) {
          matched.add(MatchedSubstring(offset: m.offset, length: m.length));
        }
        list.add(
          Prediction(
            description: item.description,
            placeId: item.placeId,
            matchedSubstrings: matched,
          ),
        );
      }
      return PlacesAutocompleteResponse(
        status: list.isEmpty ? 'ZERO_RESULTS' : 'OK',
        predictions: list,
      );
    } catch (e) {
      final message = e.toString();
      final isMissingLibrary =
          message.contains('AutocompleteService') ||
          message.contains('places') ||
          message.contains('undefined');
      return PlacesAutocompleteResponse(
        status: 'UNKNOWN_ERROR',
        errorMessage: isMissingLibrary
            ? 'Maps JavaScript Places library missing. '
                  'Load maps/api/js with &libraries=places. ($e)'
            : 'Places autocomplete failed: $e',
        predictions: const [],
      );
    }
  }

  @override
  Future<PlaceDetails> getDetailsByPlaceId(String placeId) async {
    final request = JSObject();
    request['placeId'] = placeId.toJS;
    final response = await _geocode(request);
    if (response.results.isEmpty) {
      return PlaceDetails(name: '', placeId: placeId);
    }

    final result = response.results.first;
    return PlaceDetails(
      name: result.formattedAddress ?? '',
      placeId: result.placeId,
      formattedAddress: result.formattedAddress,
      geometry: result.geometry,
    );
  }

  @override
  Future<GeocodingResponse> searchByLocation(Location location) {
    final request = JSObject();
    request['location'] = _LatLng(location.lat, location.lng);
    return _geocode(request);
  }

  Future<GeocodingResponse> _geocode(JSObject request) async {
    try {
      final response = await _geocoder.geocode(request);
      final list = <GeocodingResult>[];
      for (final item in response.results.toDart) {
        list.add(
          GeocodingResult(
            placeId: item.placeId,
            formattedAddress: item.formattedAddress,
            types: item.types?.toDart.map((t) => t.toDart).toList() ?? const [],
            geometry: Geometry(
              location: Location(
                lat: item.geometry.location.lat().toDouble(),
                lng: item.geometry.location.lng().toDouble(),
              ),
            ),
          ),
        );
      }
      return GeocodingResponse(status: list.isEmpty ? 'ZERO_RESULTS' : 'OK', results: list);
    } catch (e) {
      return GeocodingResponse(
        status: 'UNKNOWN_ERROR',
        errorMessage: 'Geocoder failed: $e',
        results: const [],
      );
    }
  }
}
