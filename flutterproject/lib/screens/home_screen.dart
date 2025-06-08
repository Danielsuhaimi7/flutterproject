import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'parking_map_screen.dart'; // ← Make sure you create this screen
import 'report_screen.dart';
import 'history_screen.dart';
import 'ai_prediction_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  GoogleMapController? _mapController;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(2.9264, 101.6424), // MMU Cyberjaya
    zoom: 17,
  );

  Set<Marker> _buildMarkers(BuildContext context) {
    return {
      Marker(
        markerId: const MarkerId('fci_parking'),
        position: const LatLng(2.9280382, 101.6409516),
        infoWindow: const InfoWindow(title: 'MMU FCI Parking Area'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ParkingMapScreen()),
          );
        },
      ),
    };
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AIPredictionScreen()));
    }
  }

  void _goToFciParking() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          const LatLng(2.9280382, 101.6409516),
          18,
        ),
      );
    }
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
            ),
          ),

          // 🛠 Top Left Profile Icon now opens ParkingMapScreen
          Positioned(
            top: 40,
            left: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ParkingMapScreen()),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: const Icon(Icons.map, color: Colors.white), // Changed icon for clarity
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome!",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.username,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🛠 Top Right Buttons
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

          // 🎯 Bottom Info Card
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

      // 🔻 Bottom Navigation Bar
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.navigation),
              label: 'Navigation',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph),
              label: 'AI Prediction',
            ),
          ],
        ),
      ),
    );
  }
}
