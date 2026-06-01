import 'package:place_pickarte/src/helpers/extensions.dart';
import 'package:place_pickarte/src/services/google/geocoding.dart';

/// Types that are too vague or meaningless for a street-level address.
const _junkTypes = {
  'plus_code',
  'postal_code',
  'postal_code_suffix',
  'postal_code_prefix',
  'country',
};

/// Known "unnamed road" strings across common locales.
const _unnamedPatterns = [
  'unnamed road',
  'adsız yol',
  'adı olmayan yol',
  'isimsiz yol',
  'без названия',
  'route sans nom',
  'strada senza nome',
  'sin nombre',
  'sem nome',
];

/// Plus code pattern: 4+ alphanumeric chars, a "+", then 2+ more.
/// Catches cases where the type array doesn't include "plus_code"
/// but the formatted address starts with one (e.g. "GCG2+R5 Baku").
final _plusCodeRegex = RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}');

/// Picks the best usable result from a reverse geocoding response.
///
/// Google returns results roughly ordered by specificity, but the first
/// result is often a plus code or unnamed road. This function skips junk
/// and returns the first meaningful result.
///
/// Returns `null` if every result is junk.
GeocodingResult? selectBestResult(List<GeocodingResult> results) {
  '${results.length} results received'.logiosa();

  for (var i = 0; i < results.length; i++) {
    final result = results[i];
    final reason = _junkReason(result);

    if (reason != null) {
      '[$i] skipped ($reason): ${result.formattedAddress}'.logiosa();
      continue;
    }

    '[$i] selected: ${result.formattedAddress} (types: ${result.types.join(', ')})'.logiosa();
    return result;
  }

  'no usable result found'.logiosa();
  return null;
}

/// Returns the reason a result is junk, or `null` if it's usable.
String? _junkReason(GeocodingResult result) {
  final types = result.types;
  final address = result.formattedAddress ?? '';

  if (types.contains('plus_code')) return 'plus_code type';
  if (_plusCodeRegex.hasMatch(address)) return 'plus_code in address';

  if (types.isNotEmpty && types.every((t) => _junkTypes.contains(t))) {
    return 'too vague (${types.join(', ')})';
  }

  final lower = address.toLowerCase();
  final match = _unnamedPatterns.cast<String?>().firstWhere(
        (p) => lower.contains(p!),
        orElse: () => null,
      );
  if (match != null) return 'unnamed road ($match)';

  return null;
}
