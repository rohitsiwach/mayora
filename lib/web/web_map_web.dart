// Web-only implementations using Google Maps JavaScript API via platform views.
// Requires the Google Maps JS script with &libraries=places to be loaded in web/index.html.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web; // For platformViewRegistry on web

import 'package:flutter/material.dart';

class WebMapController {
  dynamic _map; // JS Map instance
  dynamic _marker; // JS Marker instance

  void _attach(dynamic map) {
    _map = map;
  }

  void setMarker(double lat, double lng, {bool animate = true}) {
    if (_map == null) return;
    final pos = js_util.jsify({'lat': lat, 'lng': lng});
    if (_marker == null) {
      final gmaps = js_util.getProperty(html.window, 'google');
      final maps = js_util.getProperty(gmaps, 'maps');
      _marker = js_util.callConstructor(js_util.getProperty(maps, 'Marker'), [
        js_util.jsify({'position': pos, 'map': _map, 'draggable': true}),
      ]);
      // Drag handler
      js_util.callMethod(_marker, 'addListener', [
        'dragend',
        js_util.allowInterop((event) {
          final ll = js_util.getProperty(event, 'latLng');
          final newLat = js_util.callMethod(ll, 'lat', []);
          final newLng = js_util.callMethod(ll, 'lng', []);
          if (animate) {
            js_util.callMethod(_map, 'panTo', [
              js_util.jsify({'lat': newLat, 'lng': newLng}),
            ]);
          }
        }),
      ]);
    } else {
      js_util.callMethod(_marker, 'setPosition', [pos]);
    }
    if (animate) {
      js_util.callMethod(_map, 'panTo', [pos]);
      js_util.callMethod(_map, 'setZoom', [15]);
    }
  }
}

class WebGoogleMapView extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng)? onMapClick;
  final void Function(WebMapController controller)? onCreated;

  const WebGoogleMapView({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.onMapClick,
    this.onCreated,
  });

  @override
  State<WebGoogleMapView> createState() => _WebGoogleMapViewState();
}

class _WebGoogleMapViewState extends State<WebGoogleMapView> {
  late final String _viewType;
  final WebMapController _controller = WebMapController();

  @override
  void initState() {
    super.initState();
    _viewType = 'web-map-${DateTime.now().microsecondsSinceEpoch}';

    // Register a factory that creates a DivElement for the map
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final mapDiv = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '0';

      // Initialize the JS Map
      final gmaps = js_util.getProperty(html.window, 'google');
      final maps = js_util.getProperty(gmaps, 'maps');
      final mapOptions = js_util.jsify({
        'center': {'lat': widget.initialLat, 'lng': widget.initialLng},
        'zoom': 14,
        'mapTypeId': 'roadmap',
        'streetViewControl': false,
        'mapTypeControl': false,
        'fullscreenControl': false,
      });
      final map = js_util.callConstructor(js_util.getProperty(maps, 'Map'), [
        mapDiv,
        mapOptions,
      ]);
      _controller._attach(map);
      // Initial marker
      _controller.setMarker(
        widget.initialLat,
        widget.initialLng,
        animate: false,
      );

      // Click handler to place marker and notify Dart
      if (widget.onMapClick != null) {
        js_util.callMethod(map, 'addListener', [
          'click',
          js_util.allowInterop((event) {
            final ll = js_util.getProperty(event, 'latLng');
            final lat = js_util.callMethod(ll, 'lat', []);
            final lng = js_util.callMethod(ll, 'lng', []);
            _controller.setMarker(lat, lng);
            widget.onMapClick!(lat, lng);
          }),
        ]);
      }

      // Created callback
      widget.onCreated?.call(_controller);
      return mapDiv;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}

class WebPlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final List<String>? countries;
  final void Function(double lat, double lng, String description)?
  onPlaceSelected;

  const WebPlacesAutocompleteField({
    super.key,
    required this.controller,
    this.countries,
    this.onPlaceSelected,
  });

  @override
  State<WebPlacesAutocompleteField> createState() =>
      _WebPlacesAutocompleteFieldState();
}

class _WebPlacesAutocompleteFieldState
    extends State<WebPlacesAutocompleteField> {
  late final String _viewType;
  late final html.InputElement _input;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-places-input-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.boxSizing = 'border-box'
        ..style.padding = '0'
        ..style.margin = '0';

      _input = html.InputElement()
        ..placeholder = 'Search for a location...'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.padding = '0 12px'
        ..style.border = 'none'
        ..style.borderRadius = '0 0 8px 8px'
        ..style.fontSize = '14px'
        ..style.fontFamily =
            'Roboto, -apple-system, BlinkMacSystemFont, sans-serif'
        ..style.outline = 'none'
        ..style.boxSizing = 'border-box'
        ..style.backgroundColor = 'transparent';

      _input.value = widget.controller.text;
      _input.onInput.listen((event) {
        widget.controller.text = _input.value ?? '';
      });

      container.append(_input); // Initialize Places Autocomplete
      final gmaps = js_util.getProperty(html.window, 'google');
      final maps = js_util.getProperty(gmaps, 'maps');
      final placesNs = js_util.getProperty(maps, 'places');

      final opts = <String, dynamic>{
        'fields': ['formatted_address', 'geometry'],
      };
      if (widget.countries != null && widget.countries!.isNotEmpty) {
        opts['componentRestrictions'] = {'country': widget.countries};
      }

      final autocomplete = js_util.callConstructor(
        js_util.getProperty(placesNs, 'Autocomplete'),
        [_input, js_util.jsify(opts)],
      );

      js_util.callMethod(autocomplete, 'addListener', [
        'place_changed',
        js_util.allowInterop(() {
          final place = js_util.callMethod(autocomplete, 'getPlace', []);
          final geometry = js_util.getProperty(place, 'geometry');
          if (geometry != null) {
            final loc = js_util.getProperty(geometry, 'location');
            final lat = js_util.callMethod(loc, 'lat', []);
            final lng = js_util.callMethod(loc, 'lng', []);
            final address =
                (js_util.getProperty(place, 'formatted_address') ?? '')
                    .toString();
            widget.controller.text = address;
            widget.onPlaceSelected?.call(lat, lng, address);
          }
        }),
      ]);

      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Material-styled container matching TextField appearance
    return Container(
      height: 64, // Match TextField height with label
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 6, right: 12),
            child: Text(
              'Address *',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: HtmlElementView(viewType: _viewType),
            ),
          ),
        ],
      ),
    );
  }
}
