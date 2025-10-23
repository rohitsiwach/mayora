import 'package:flutter/material.dart';

// Stub implementations used on non-web platforms. These prevent import errors
// when referencing web-only widgets from shared code.

class WebMapController {
  void setMarker(double lat, double lng, {bool animate = true}) {}
}

class WebGoogleMapView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WebPlacesAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final List<String>? countries;
  final void Function(double lat, double lng, String description)? onPlaceSelected;

  const WebPlacesAutocompleteField({
    super.key,
    required this.controller,
    this.countries,
    this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    // On non-web platforms, fall back to a plain, disabled box
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Address *',
        hintText: 'Search not available on this platform',
      ),
    );
  }
}
