import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // ⭐️ Leaflet Package
import 'package:latlong2/latlong.dart';      // ⭐️ Coordinates Package
import 'package:url_launcher/url_launcher.dart'; 
import '../models/models.dart';

class DeliveryMapScreen extends StatefulWidget {
  final Order order;

  const DeliveryMapScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  // Default to Nairobi
  static const LatLng _defaultLocation = LatLng(-1.2921, 36.8219);

  late final LatLng _pickupPos;
  late final LatLng _dropoffPos;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _setupLocations();
  }

  void _setupLocations() {
    // 1. Pickup Location (Farmer)
    // In a real app, you'd fetch this from the database.
    // Using a slight offset from Nairobi for demo.
    _pickupPos = const LatLng(-1.2921, 36.8219);

    // 2. Dropoff Location (Customer)
    if (widget.order.deliveryLocation.isNotEmpty) {
      _dropoffPos = LatLng(
        widget.order.deliveryLocation['lat'] ?? -1.3000, 
        widget.order.deliveryLocation['lng'] ?? 36.8500
      );
    } else {
      _dropoffPos = const LatLng(-1.3000, 36.8500);
    }
  }

  // 🚀 Opens Google Maps / Waze App for turn-by-turn driving
  Future<void> _openNavigation() async {
    final lat = _dropoffPos.latitude;
    final lng = _dropoffPos.longitude;
    
    // This URI works on both Android and iOS to open the native maps app
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Maps app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Route (Leaflet)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation, // Center map
              initialZoom: 13.0,
            ),
            children: [
              // 1. The Map Tiles (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.agriconnect', // Add your package name here
              ),

              // 2. The Markers
              MarkerLayer(
                markers: [
                  // PICKUP MARKER (Green)
                  Marker(
                    point: _pickupPos,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: const Text("Pickup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),

                  // DROPOFF MARKER (Red)
                  Marker(
                    point: _dropoffPos,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: const Text("Dropoff", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Floating Card at Bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Destination: ${widget.order.customerName}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Item: ${widget.order.quantity}x ${widget.order.productName}"),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openNavigation,
                        icon: const Icon(Icons.navigation),
                        label: const Text("Start Driving Navigation"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}