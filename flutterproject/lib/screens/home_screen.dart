import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parking_map_screen.dart';
import 'report_screen.dart';
import 'history_screen.dart';
import 'ai_prediction_screen.dart';
import 'navigation_screen.dart';
import '../services/api_service.dart';
import 'parking_layout_editor.dart';
import 'profile_screen.dart';
import 'parking_custom_layout_screen.dart';
import 'reserve_custom_parking_screen.dart';
import 'manage_users_screen.dart';
import 'view_reports_screen.dart';

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
  List<Map<String, dynamic>> _fetchedParkings = [];

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(2.85873708245567, 101.75804653011701),
    zoom: 16,
  );

  bool _isCreatingParking = false;
  LatLng? _newParkingLocation;

  @override
  void initState() {
    super.initState();
    _loadAllParkingLocations();
  }

  Future<void> _loadAllParkingLocations() async {
    final data = await ApiService.getParkingLocations();
    setState(() {
      _fetchedParkings = List<Map<String, dynamic>>.from(data);
    });
  }

  Set<Marker> _buildMarkers(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('sky_parkg'),
        position: const LatLng(2.861523104958513, 101.75613679731536),
        infoWindow: const InfoWindow(title: 'Sky Park'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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

    for (var parking in _fetchedParkings) {
      markers.add(
        Marker(
          markerId: MarkerId(parking['name']),
          position: LatLng(parking['latitude'], parking['longitude']),
          infoWindow: InfoWindow(title: parking['name']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () async {
            if (widget.role == 'admin') {
              _showSlotLayoutDialog(parking);
            } else {
                final layout = await ApiService.getCustomLayout(parking['name']);
                print('📦 Layout for ${parking['name']}: $layout');

                if (layout.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReserveCustomParkingScreen(parkingName: parking['name']),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No parking layout has been saved for this parking yet.')),
                  );
                }
            }
          }
        ),
      );
    }

    if (_newParkingLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('new_parking'),
          position: _newParkingLocation!,
          infoWindow: const InfoWindow(title: 'New Parking (Temp)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReserveCustomParkingScreen(parkingName: 'New Parking'),
              ),
            );
          },
        ),
      );
    }
    return markers;
  }

  void _onMapTapForParking(LatLng position) {
    setState(() {
      _newParkingLocation = position;
      _isCreatingParking = false;
    });

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create Parking Here?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Lat: ${position.latitude}, Lng: ${position.longitude}"),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Parking Name"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ApiService.addParkingLocation(
                position.latitude,
                position.longitude,
                name: nameController.text.trim().isEmpty
                    ? "Unnamed"
                    : nameController.text.trim(),
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Parking saved")),
                );
                _loadAllParkingLocations();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to save parking location")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSlotLayoutDialog(Map<String, dynamic> parking) {
    final TextEditingController slotController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set Slots for ${parking['name']}"),
        content: TextField(
          controller: slotController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Number of Slots"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final int? slotCount = int.tryParse(slotController.text.trim());
              if (slotCount == null || slotCount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid slot count")),
                );
                return;
              }

              Navigator.of(ctx).pop();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ParkingCustomLayoutScreen(
                    parkingName: parking['name'],
                    totalSlots: slotCount,
                  ),
                ),
              );
            },
            child: const Text("Customize Layout"),
          ),
        ],
      ),
    );
  }

  void _showDeleteParkingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedParking;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Delete Parking"),
              content: DropdownButtonFormField<String>(
                hint: const Text("Select Parking"),
                value: selectedParking,
                items: _fetchedParkings.map((parking) {
                  return DropdownMenuItem<String>(
                    value: parking['name'],
                    child: Text(parking['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedParking = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedParking != null) {
                      final success = await ApiService.deleteParkingLocation(selectedParking!);
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Parking deleted")),
                        );
                        _loadAllParkingLocations();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("❌ Failed to delete")),
                        );
                      }
                    }
                  },
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.pushNamed(context, '/navigation');
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AIPredictionScreen()));
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
              onMapCreated: (controller) => _mapController = controller,
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome!",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(widget.username,
                        style: const TextStyle(color: Colors.black, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin)
            Positioned(
              bottom: 120,
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
                    const Text("Admin Panel",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text("Create New Parking"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple),
                      onPressed: () {
                        setState(() {
                          _isCreatingParking = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Tap on the map to place a new parking.")),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Delete Parking"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                      ),
                      onPressed: _showDeleteParkingDialog,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.report),
                      label: const Text("View Reports"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ViewReportsScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text("Manage Users"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                        );
                      },
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
            BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'Parking Prediction'),
          ],
        ),
      ),
    );
  }
}
