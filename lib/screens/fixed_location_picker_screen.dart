import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class FixedLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const FixedLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<FixedLocationPickerScreen> createState() => _FixedLocationPickerScreenState();
}

class _FixedLocationPickerScreenState extends State<FixedLocationPickerScreen> {
  double? _latitude;
  double? _longitude;
  String _address = '';
  bool _isLoading = false;
  final TextEditingController _addressController = TextEditingController();
  
  // Map controller
  final MapController _mapController = MapController();
  final double _zoom = 15.0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
    });

    // Initialize with provided coordinates if available
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() {
        _latitude = widget.initialLatitude;
        _longitude = widget.initialLongitude;
        _address = "Lokasi yang dipilih";
        _addressController.text = _address;
        _isLoading = false;
      });
      return;
    }

    // Otherwise try to get current location
    try {
      await _requestLocationPermission();
      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = "Lokasi saat ini";
        _addressController.text = _address;
        _isLoading = false;
      });
    } catch (e) {
      // Default to UNEJ location if can't get current location
      setState(() {
        _latitude = -8.1733;
        _longitude = 113.7022;
        _address = "Universitas Jember";
        _addressController.text = _address;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _requestLocationPermission();
      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = "Lokasi saat ini";
        _addressController.text = _address;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat mengakses lokasi saat ini'),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _address = "Lokasi yang dipilih pada peta (${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})";
      _addressController.text = _address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi di Peta'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Gunakan lokasi saat ini',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Real map view
                Expanded(
                  flex: 3,
                  child: _latitude != null && _longitude != null
                      ? FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(_latitude!, _longitude!),
                            initialZoom: _zoom,
                            onTap: _onMapTap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.meetme_firebase',
                              maxZoom: 19,
                            ),
                            // Add marker at selected location
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 80.0,
                                  height: 80.0,
                                  point: LatLng(_latitude!, _longitude!),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(25),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${_latitude!.toStringAsFixed(6).substring(0, 8)}, ${_longitude!.toStringAsFixed(6).substring(0, 8)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Add attribution
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap contributors',
                                  onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Center(
                          child: Text('Memuat peta...'),
                        ),
                ),
                
                // Location details
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Alamat Lokasi',
                            hintText: 'Masukkan alamat lokasi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _latitude != null && _longitude != null
                                ? () {
                                    Navigator.pop(context, {
                                      'latitude': _latitude,
                                      'longitude': _longitude,
                                      'address': _addressController.text,
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5BBFCB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Pilih Lokasi Ini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
