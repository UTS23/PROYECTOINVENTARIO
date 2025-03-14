import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_generator_screen.dart';

class EquiposDisponiblesPage extends StatefulWidget {
  const EquiposDisponiblesPage({Key? key}) : super(key: key);

  @override
  _EquiposDisponiblesPageState createState() => _EquiposDisponiblesPageState();
}

class _EquiposDisponiblesPageState extends State<EquiposDisponiblesPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String usuarioActual = "Cargando...";

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    setState(() {
      usuarioActual = email ?? "Desconocido";
    });
  }

  // Función para generar el QR del equipo
  void _generarQR(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrGeneratorScreen(data: data),
      ),
    );
  }

  // Funcionalidad para marcar el equipo como "No Reparado"
  void _mostrarDialogoMotivo(
      BuildContext context, String equipoId, Map<String, dynamic> data) {
    TextEditingController motivoController = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Motivo de No Reparación",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextFormField(
                controller: motivoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Ingrese el motivo",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar")),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    onPressed: () {
                      String motivo = motivoController.text.trim();
                      if (motivo.isNotEmpty) {
                        _enviarAEquiposNoReparados(equipoId, data, motivo);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Enviar"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Registra la acción en la colección "auditoria"
  Future<void> _registrarEnAuditoria(
      String accion, String equipoId, Map<String, dynamic> data,
      [String? motivo]) async {
    await FirebaseFirestore.instance.collection('auditoria').add({
      "accion": accion,
      "equipoId": equipoId,
      "usuario": usuarioActual,
      "marca": data["marca"],
      "modelo": data["modelo"],
      "motivo": motivo ?? "",
      "fecha": FieldValue.serverTimestamp(),
    });
  }

  // Mueve el equipo a la colección "equipos_no_reparados"
  Future<void> _enviarAEquiposNoReparados(
      String equipoId, Map<String, dynamic> data, String motivo) async {
    try {
      await FirebaseFirestore.instance.collection('equipos_no_reparados').add({
        "marca": data["marca"],
        "modelo": data["modelo"],
        "estado": "No reparado",
        "motivo": motivo,
        "fecha": FieldValue.serverTimestamp(),
      });
      // Elimina el equipo de la colección de disponibles
      await FirebaseFirestore.instance
          .collection('equipos_disponibles')
          .doc(equipoId)
          .delete();
      await _registrarEnAuditoria(
          "Movido a No Reparado", equipoId, data, motivo);
    } catch (e) {
      print("Error al mover el equipo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("✅ Equipos Disponibles"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Buscar equipo...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipos_disponibles')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No hay equipos disponibles"));
                }

                final equipos = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final marca = (data['marca'] as String).toLowerCase();
                  final modelo = (data['modelo'] as String).toLowerCase();
                  return marca.contains(searchQuery) ||
                      modelo.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: equipos.length,
                  itemBuilder: (context, index) {
                    final equipo = equipos[index];
                    final data = equipo.data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: ListTile(
                        leading:
                            const Icon(Icons.devices, color: Colors.blueAccent),
                        title: Text("${data['marca']} - ${data['modelo']}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Estado: ${data['estado']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code,
                                  color: Colors.green),
                              onPressed: () => _generarQR(context, data),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == "No Reparado") {
                                  _mostrarDialogoMotivo(
                                      context, equipo.id, data);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: "No Reparado",
                                  child: Text("Marcar como No Reparado"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implementa aquí la funcionalidad para agregar un nuevo equipo.
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
