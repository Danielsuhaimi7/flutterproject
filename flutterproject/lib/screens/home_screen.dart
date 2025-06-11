import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parking_map_screen.dart';
import 'report_screen.dart';
import 'history_screen.dart';
import 'ai_prediction_screen.dart';
import 'navigation_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String role;

  const HomeScreen({
    super.key,
    required this.username,
    this.role = 'user',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  GoogleMapController? _mapController;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(2.9264, 101.6424),
    zoom: 17,
  );

  bool _isCreatingParking = false;
  LatLng? _newParkingLocation;
  List<LatLng> _publicParkings = []; // 👈 All saved parkings from backend

  Set<Marker> _buildMarkers(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('fci_parking'),
        position: const LatLng(2.9280382, 101.6409516),
        infoWindow: const InfoWindow(title: 'MMU FCI Parking Area'),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final reservedSlot = prefs.getString('reservedSlot') ?? 'A1';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParkingMapScreen(slotToNavigate: reservedSlot),
            ),
          );
        },
      ),
    };

    if (_newParkingLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('new_parking'),
          position: _newParkingLocation!,
          infoWindow: const InfoWindow(title: 'New Parking (Temp)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return markers;
  }

  void _onMapTapForParking(LatLng position) async {
    setState(() {
      _newParkingLocation = position;
      _isCreatingParking = false;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create Parking Here?"),
        content: Text("Latitude: ${position.latitude}\nLongitude: ${position.longitude}"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Parking created (simulated)")),
              );
              // TODO: Send to backend later
            },
          ),
        ],
      ),
    );
  }

  void _onNavTap(int index) async {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.pushNamed(context, '/navigation');
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AIPredictionScreen()));
    }
  }

  void _goToFciParking() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(const LatLng(2.9280382, 101.6409516), 18),
    );
  }

  void _goToCurrentLocation() async {
    if (_mapController != null) {
      var location = await _mapController!.getVisibleRegion();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            (location.northeast.latitude + location.southwest.latitude) / 2,
            (location.northeast.longitude + location.southwest.longitude) / 2,
          ),
          17,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role == 'admin';

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              markers: _buildMarkers(context),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onTap: _isCreatingParking ? _onMapTapForParking : null,
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final reservedSlot = prefs.getString('reservedSlot') ?? 'A1';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParkingMapScreen(slotToNavigate: reservedSlot),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: const Icon(Icons.map, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.username, style: const TextStyle(color: Colors.black, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Column(
              children: [
                const Icon(Icons.notifications_none_rounded, size: 28),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "btn1",
                  backgroundColor: Colors.blue,
                  onPressed: _goToFciParking,
                  child: const Icon(Icons.local_parking, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "btn2",
                  backgroundColor: Colors.green,
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),
          if (isAdmin)
            Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text("Admin Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text("Create New Parking"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
                      onPressed: () {
                        setState(() {
                          _isCreatingParking = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Tap on the map to place a new parking.")),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Manage Parking Slots"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
                      onPressed: () {
                        // TODO: Navigate to admin parking management screen
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.report),
                      label: const Text("View Reports"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
                      onPressed: () {
                        // TODO: Navigate to admin report viewer
                      },
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("Daniel Danish bin Suhaimi", style: TextStyle(color: Colors.white)),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.smart_display, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text("Smart Campus Parking System", style: TextStyle(color: Colors.white)),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.navigation), label: 'Navigation'),
            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'AI Prediction'),
          ],
        ),
      ),
    );
  }
}
