import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  List<Map<String, dynamic>> _deliveries = [];

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

  Future<void> _deleteDelivery(int id) async {
    await DatabaseHelper().deleteDelivery(id);
    _loadDeliveries();
  }

  Future<void> _openWaze(double lat, double lng) async {
    final uri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareWhatsApp(double lat, double lng) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final String text = "Ubicación de entrega: $googleMapsUrl";
    final Uri whatsappUrl = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Entregas Guardadas'),
      ),
      body: _deliveries.isEmpty
          ? const Center(child: Text('No hay entregas guardadas.'))
          : ListView.builder(
              itemCount: _deliveries.length,
              itemBuilder: (context, index) {
                final item = _deliveries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.location_pin, color: Colors.red),
                    title: Text(item['title'] ?? 'Sin nombre'),
                    subtitle: Text(item['description'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.directions_car, color: Colors.blue),
                          onPressed: () => _openWaze(item['latitude'], item['longitude']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          onPressed: () => _shareWhatsApp(item['latitude'], item['longitude']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _deleteDelivery(item['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
