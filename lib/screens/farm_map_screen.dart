import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({super.key});

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  final _mapController = MapController();
  LatLng _selected = const LatLng(8.5874, 81.2152);
  String _district = 'Trincomalee';
  bool _locating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final district = await FirebaseBackend.currentDistrict();
    final coordinates = WeatherService.coordinatesFor(district);
    final center = LatLng(coordinates.$1, coordinates.$2);
    if (!mounted) return;
    setState(() {
      _district = district;
      _selected = center;
    });
    if (_mapReady) _mapController.move(center, 11);
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _MapLocationException('Turn on phone location services.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _MapLocationException(
          'Location permission is required to show your position.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final current = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selected = current);
      _mapController.move(current, 16);
    } catch (error) {
      if (mounted) {
        showDemoMessage(
          context,
          error is _MapLocationException
              ? tr(error.message)
              : tr('Unable to get your current location.'),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AgriPage(
      title: 'Farm Map',
      subtitle: 'Free OpenStreetMap • No API key or billing',
      scrollable: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tr('Selected farm location')}: ${tr(_district)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: tr('Use current location'),
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selected,
                  initialZoom: 11,
                  onMapReady: () => _mapReady = true,
                  onTap: (_, point) => setState(() => _selected = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.agriai',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected,
                        width: 54,
                        height: 54,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primaryDark,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_selected.latitude.toStringAsFixed(5)}, '
            '${_selected.longitude.toStringAsFixed(5)} • '
            '${tr('Tap the map to move the farm marker')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLocationException implements Exception {
  const _MapLocationException(this.message);

  final String message;
}
