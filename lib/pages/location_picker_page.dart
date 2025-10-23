import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
// Conditional import: on web, use HTML-based map and autocomplete; on mobile, stubs do nothing
import '../web/web_map_stub.dart'
    if (dart.library.html) '../web/web_map_web.dart';
import '../models/work_location.dart';
import '../services/location_settings_service.dart';

class LocationPickerPage extends StatefulWidget {
  final String organizationId;
  final WorkLocation? existingLocation;

  const LocationPickerPage({
    super.key,
    required this.organizationId,
    this.existingLocation,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final LocationSettingsService _locationService = LocationSettingsService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(48.1351, 11.5820); // Default: Munich
  Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _isSaving = false;
  WebMapController? _webMapController; // Web-only controller

  @override
  void initState() {
    super.initState();
    if (widget.existingLocation != null) {
      _nameController.text = widget.existingLocation!.name;
      _addressController.text = widget.existingLocation!.address;
      _radiusController.text = widget.existingLocation!.radiusMeters
          .toInt()
          .toString();
      _selectedLocation = LatLng(
        widget.existingLocation!.latitude,
        widget.existingLocation!.longitude,
      );
      _updateMarker(_selectedLocation);
    } else {
      _radiusController.text = '50'; // Default 50 meters
      _updateMarker(_selectedLocation);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng tapLocation) async {
    setState(() {
      _isLoading = true;
      _selectedLocation = tapLocation;
    });

    try {
      // Reverse geocoding to get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        tapLocation.latitude,
        tapLocation.longitude,
      );

      String fetchedAddress = 'Selected Location';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        fetchedAddress = [
          place.street,
          place.locality,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      setState(() {
        _addressController.text = fetchedAddress;
        _updateMarker(tapLocation);
      });

      // Animate camera to the tapped location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(tapLocation, 15),
      );
    } catch (e) {
      _showSnackBar('Error getting address: $e', isError: true);
      setState(() {
        _addressController.text =
            'Lat: ${tapLocation.latitude.toStringAsFixed(4)}, Lng: ${tapLocation.longitude.toStringAsFixed(4)}';
        _updateMarker(tapLocation);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          draggable: true,
          onDragEnd: (newPosition) => _onMapTap(newPosition),
        ),
      };
    });
  }

  void _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission (skip on web as it's handled by browser)
      if (!kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showSnackBar('Location permission denied', isError: true);
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _showSnackBar(
            'Location permissions are permanently denied. Please enable in settings.',
            isError: true,
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String fetchedAddress = 'Your Current Location';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        fetchedAddress = [
          place.street,
          place.locality,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      setState(() {
        _selectedLocation = currentLocation;
        _addressController.text = fetchedAddress;
        if (!kIsWeb) {
          _updateMarker(currentLocation);
        }
      });

      // Animate camera to current location (mobile only)
      if (!kIsWeb) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, 15),
        );
      }

      _showSnackBar('Location updated to current position.');
    } catch (e) {
      _showSnackBar('Could not get current location: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a location name', isError: true);
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showSnackBar('Please select a location on the map', isError: true);
      return;
    }

    final radius = double.tryParse(_radiusController.text);
    if (radius == null || radius <= 0) {
      _showSnackBar('Please enter a valid radius', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final location = WorkLocation(
        id: widget.existingLocation?.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        radiusMeters: radius,
        organizationId: widget.organizationId,
        createdAt: widget.existingLocation?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingLocation != null) {
        await _locationService.updateWorkLocation(location);
      } else {
        await _locationService.addWorkLocation(location);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showSnackBar('Error saving location: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Web placeholder removed: now using real web map via WebGoogleMapView

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingLocation != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Location' : 'Add Location'),
        backgroundColor: const Color(0xFF2962FF),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveLocation,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map or Web Placeholder
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: kIsWeb
                ? WebGoogleMapView(
                    initialLat: _selectedLocation.latitude,
                    initialLng: _selectedLocation.longitude,
                    onMapClick: (lat, lng) {
                      _onMapTap(LatLng(lat, lng));
                    },
                    onCreated: (controller) {
                      _webMapController = controller;
                    },
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    onTap: _onMapTap,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    mapType: MapType.normal,
                  ),
          ),

          // Form Section
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current Location Button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _useCurrentLocation,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text('Use My Current Location'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Location Name *',
                        hintText: 'e.g., Head Office, Munich Branch',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Address with Autocomplete (web and mobile)
                    if (kIsWeb)
                      WebPlacesAutocompleteField(
                        controller: _addressController,
                        countries: const ["de", "at", "ch"],
                        onPlaceSelected: (lat, lng, description) {
                          final latLng = LatLng(lat, lng);
                          setState(() {
                            _selectedLocation = latLng;
                            _addressController.text = description;
                          });
                          // Update web map marker
                          _webMapController?.setMarker(lat, lng, animate: true);
                        },
                      )
                    else
                      GooglePlaceAutoCompleteTextField(
                        textEditingController: _addressController,
                        googleAPIKey: "AIzaSyABnf6w7P5U8y7S2C1uqQ1VZ-BrJFOmeAY",
                        inputDecoration: InputDecoration(
                          labelText: 'Address *',
                          hintText: 'Search for a location...',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        debounceTime: 800,
                        countries: const ["de", "at", "ch"],
                        isLatLngRequired: true,
                        getPlaceDetailWithLatLng:
                            (Prediction prediction) async {
                              if (prediction.lat != null &&
                                  prediction.lng != null) {
                                final latLng = LatLng(
                                  double.parse(prediction.lat!),
                                  double.parse(prediction.lng!),
                                );
                                setState(() {
                                  _selectedLocation = latLng;
                                  _addressController.text =
                                      prediction.description ?? '';
                                  _updateMarker(latLng);
                                });
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(latLng, 15),
                                );
                              }
                            },
                        itemClick: (Prediction prediction) {
                          _addressController.text =
                              prediction.description ?? '';
                          _addressController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: prediction.description?.length ?? 0,
                                ),
                              );
                        },
                        seperatedBuilder: const Divider(height: 1),
                        containerHorizontalPadding: 10,
                        itemBuilder: (context, index, Prediction prediction) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prediction.description ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        isCrossBtnShown: true,
                      ),
                    const SizedBox(height: 20),

                    // Radius
                    TextField(
                      controller: _radiusController,
                      decoration: InputDecoration(
                        labelText: 'Radius (meters) *',
                        hintText: 'e.g., 50',
                        prefixIcon: const Icon(Icons.radar),
                        suffixText: 'm',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Coordinates Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selected Coordinates:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Latitude: ${_selectedLocation.latitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Longitude: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveLocation,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Location' : 'Save Location',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading && !_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
