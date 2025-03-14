import 'package:flutter/material.dart';
import 'package:inventario/bajas.dart';
import 'package:inventario/disponibles.dart';
import 'package:inventario/equipos_no_reparados.dart';
import 'package:inventario/manteni.dart';
import 'package:inventario/nuevos.dart';
import 'package:inventario/reparados.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({Key? key}) : super(key: key);

  @override
  _InventarioPageState createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCategories = [];

  final List<Map<String, dynamic>> _categories = [
    {
      "title": "Equipos Nuevos",
      "color": Colors.blue,
      "icon": Icons.new_releases,
      "page": const EquiposNuevosPage()
    },
    {
      "title": "Mantenimiento",
      "color": Colors.orange,
      "icon": Icons.build,
      "page": const EquiposMantenimientoPage()
    },
    {
      "title": "Reparados",
      "color": Colors.green,
      "icon": Icons.check_circle,
      "page": const EquiposReparadosPage()
    },
    {
      "title": "Disponibles",
      "color": Colors.purple,
      "icon": Icons.devices,
      "page": const EquiposDisponiblesPage()
    },
    {
      "title": "Dar de Baja",
      "color": Colors.red,
      "icon": Icons.delete_forever,
      "page": const EquiposBajaPage()
    },
    {
      "title": "No Reparados",
      "color": Colors.grey,
      "icon": Icons.error,
      "page": const EquiposNoReparadosPage()
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredCategories = _categories;
  }

  void _resetCategories() {
    setState(() {
      _searchController.clear();
      _filteredCategories = _categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Inventario",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCategories,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  _filteredCategories = _categories
                      .where((category) => category["title"]
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: "🔍 Buscar categoría...",
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _resetCategories,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = _filteredCategories[index];
                  return _buildCategoryCard(
                    context,
                    category["title"],
                    category["color"],
                    category["icon"],
                    category["page"],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, Color color,
      IconData icon, Widget page) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 6,
        shadowColor: color.withOpacity(0.4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
