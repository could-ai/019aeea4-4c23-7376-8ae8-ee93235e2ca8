import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';
import 'delivery_list_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Center of Puerto Rico
  final LatLng _puertoRicoCenter = const LatLng(18.2208, -66.5901);
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _deliveries = [];
  
  // Map style (using OpenStreetMap for demo purposes as it requires no key)
  // In a real production app with Mapbox/Google, you would switch the urlTemplate
  String _currentTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    final data = await DatabaseHelper().getDeliveries();
    setState(() {
      _deliveries = data;
    });
  }

  void _addMarker(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final descController = TextEditingController();
        return AlertDialog(
          title: const Text('Guardar Ubicación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Nombre del Cliente / Lugar'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Dirección / Notas'),
              ),
              const SizedBox(height: 10),
              Text('Lat: ${point.latitude.toStringAsFixed(4)}\nLng: ${point.longitude.toStringAsFixed(4)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await DatabaseHelper().insertDelivery({
                    'title': titleController.text,
                    'description': descController.text,
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                  _loadDeliveries();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openExternalMap(double lat, double lng, String type) async {
    Uri uri;
    if (type == 'waze') {
      uri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    } else if (type == 'google') {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      return;
    }
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback or error handling
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la aplicación de mapas')),
      );
    }
  }

  Future<void> _shareLocation(double lat, double lng) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final String text = "Aquí está la ubicación para la entrega: $googleMapsUrl";
    final Uri whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(text)}");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Puerto Rico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeliveryListScreen()),
              );
              _loadDeliveries(); // Refresh when returning
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _puertoRicoCenter,
              initialZoom: 9.0,
              onTap: (tapPosition, point) {
                _addMarker(point);
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _currentTileUrl,
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: _deliveries.map((delivery) {
                  return Marker(
                    point: LatLng(delivery['latitude'], delivery['longitude']),
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(16),
                            height: 250,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  delivery['title'],
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(delivery['description']),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _ActionButton(
                                      icon: Icons.directions_car,
                                      label: 'Waze',
                                      color: Colors.blue,
                                      onTap: () => _openExternalMap(
                                        delivery['latitude'],
                                        delivery['longitude'],
                                        'waze',
                                      ),
                                    ),
                                    _ActionButton(
                                      icon: Icons.map,
                                      label: 'Google',
                                      color: Colors.green,
                                      onTap: () => _openExternalMap(
                                        delivery['latitude'],
                                        delivery['longitude'],
                                        'google',
                                      ),
                                    ),
                                    _ActionButton(
                                      icon: Icons.share,
                                      label: 'WhatsApp',
                                      color: Colors.teal,
                                      onTap: () => _shareLocation(
                                        delivery['latitude'],
                                        delivery['longitude'],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _mapController.move(_puertoRicoCenter, 9.0);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 25,
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
