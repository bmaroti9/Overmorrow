import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre/maplibre.dart';

import '../services/color_service.dart';

class ThemedMapLibreMap extends StatefulWidget {
  const ThemedMapLibreMap({Key? key}) : super(key: key);

  @override
  State<ThemedMapLibreMap> createState() => _ThemedMapLibreMapState();
}

class _ThemedMapLibreMapState extends State<ThemedMapLibreMap> {
  String? _dynamicStyleString;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAndThemeStyle(Theme.of(context).colorScheme);
  }

  Future<void> _loadAndThemeStyle(ColorScheme theme) async {
    final String styleJsonStr = await rootBundle.loadString('assets/map/style.json');
    final Map<String, dynamic> styleMap = jsonDecode(styleJsonStr);

    final String surfaceHex = colorToHex(theme.surface);
    final String onSurfaceHex = colorToHex(theme.onSurfaceVariant);
    final String secondaryContainerHex = colorToHex(theme.secondaryContainer);
    final String outlineHex = colorToHex(theme.outline);
    final String outlineVariantHex = colorToHex(theme.outlineVariant);
    final String surfaceContainerHex = colorToHex(theme.surfaceContainerHighest);

    final List<dynamic> layers = styleMap['layers'];
    for (var layer in layers) {
      final String layerId = layer['id'] ?? '';

      if (layer['paint'] == null) continue;

      switch (layerId) {
        case 'background' : layer['paint']['background-color'] = surfaceHex;
        case 'water' : layer['paint']['fill-color'] = secondaryContainerHex;

        case 'water-intermittent' : layer['paint']['fill-color'] = surfaceContainerHex;
        case 'waterway-river' : layer['paint']['line-color'] = secondaryContainerHex;

        case 'water-border' : layer['paint']['line-color'] = outlineHex;
        case 'boundary_2' : layer['paint']['line-color'] = outlineHex;
        case 'boundary_3' : layer['paint']['line-color'] = outlineVariantHex;

        case 'highway-motorway' : layer['paint']['line-color'] = outlineVariantHex;
        case 'highway-trunk' : layer['paint']['line-color'] = outlineVariantHex;
        case 'highway-primary' : layer['paint']['line-color'] = secondaryContainerHex;
        case 'highway-link' : layer['paint']['line-color'] = surfaceContainerHex;
        case 'highway-area' : layer['paint']['line-color'] = surfaceContainerHex;
        case 'highway-secondary-tertiary' : layer['paint']['line-color'] = surfaceContainerHex;

        case 'label_city_capital' : layer['paint']['text-color'] = onSurfaceHex; layer['paint']['text-halo-color'] = surfaceHex;
        case 'label_city' : layer['paint']['text-color'] = onSurfaceHex; layer['paint']['text-halo-color'] = surfaceHex;
        case 'label_town' : layer['paint']['text-color'] = onSurfaceHex; layer['paint']['text-halo-color'] = surfaceHex;
      }
    }

    setState(() {
      _dynamicStyleString = jsonEncode(styleMap);
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_dynamicStyleString == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MapLibreMap(
      options: MapOptions(
        initStyle: _dynamicStyleString!,
        initCenter: Geographic(lat: 45.4385, lon: 12.338), // Note: Lng, Lat order
        initZoom: 6.0,
        maxZoom: 11.0,
      )
    );
  }
}