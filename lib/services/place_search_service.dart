import 'dart:convert';

import 'package:http/http.dart' as http;

/// One live search suggestion from OpenStreetMap Nominatim: a resolved
/// place name plus enough context (state) to disambiguate same-named towns.
class PlaceSuggestion {
  const PlaceSuggestion({required this.name, required this.state});

  final String name;
  final String? state;

  String get label => state == null || state!.isEmpty ? name : '$name, $state';
}

/// Free-text place search backed by Photon (photon.komoot.io) — a free,
/// keyless geocoder built on OpenStreetMap data with proper prefix/edge-ngram
/// indexing, so partial words like "tambara" match "Tambaram" as the user is
/// still typing. Plain Nominatim `/search` doesn't do this: it only matches
/// complete tokens, so "tambara" returns nothing until the last letter lands.
/// Photon has no country filter param on its public instance and returns
/// worldwide matches, so results are filtered to India client-side. It's a
/// free public demo service (no API key, no SLA) — fine for this app's
/// traffic, but not meant for heavy production load. The UI layer debounces
/// keystrokes before calling [search] to stay a good citizen of it.
class PlaceSearchService {
  PlaceSearchService._();

  static final PlaceSearchService instance = PlaceSearchService._();

  static const _endpoint = 'https://photon.komoot.io/api/';

  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': trimmed,
        'lang': 'en',
        'osm_tag': 'place',
        'limit': '15',
        // Bias ranking toward India (rough geographic centre) without
        // excluding other countries outright — the countrycode filter below
        // does the actual exclusion.
        'lat': '22.0',
        'lon': '79.0',
      },
    );

    // ignore: avoid_print
    print('LOCSEARCH: GET $uri');
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    // ignore: avoid_print
    print(
      'LOCSEARCH: status ${response.statusCode}, '
      'body (${response.body.length} chars): '
      '${response.body.substring(0, response.body.length.clamp(0, 500))}',
    );
    if (response.statusCode != 200) return const [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>? ?? const [];
    // ignore: avoid_print
    print('LOCSEARCH: parsed ${features.length} raw features');
    final suggestions = <PlaceSuggestion>[];
    final seen = <String>{};

    for (final feature in features) {
      final props = (feature as Map<String, dynamic>)['properties']
          as Map<String, dynamic>?;
      if (props == null) continue;
      if (props['countrycode'] != 'IN') continue;

      final name = props['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      final state = props['state'] as String?;
      final key = '${name.toLowerCase()}|${(state ?? '').toLowerCase()}';
      if (!seen.add(key)) continue;

      suggestions.add(PlaceSuggestion(name: name.trim(), state: state));
      if (suggestions.length >= 8) break;
    }

    return suggestions;
  }
}
