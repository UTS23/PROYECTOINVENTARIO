import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventario/qr_generator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EquiposReparadosPage extends StatefulWidget {
  const EquiposReparadosPage({Key? key}) : super(key: key);

  @override
  _EquiposReparadosPageState createState() => _EquiposReparadosPageState();
}

class _EquiposReparadosPageState extends State<EquiposReparadosPage> {
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

  Future<void> _registrarEnAuditoria(
      String accion, String equipoId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('auditoria').add({
      "accion": accion,
      "equipoId": equipoId,
      "usuario": usuarioActual,
      "marca": data["marca"],
      "modelo": data["modelo"],
      "fecha": FieldValue.serverTimestamp(),
    });
  }

  void _eliminarEquipoReparado(
      String equipoId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('equipos_reparados')
          .doc(equipoId)
          .delete();
      await _registrarEnAuditoria(
          "Equipo eliminado de reparados", equipoId, data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Equipo eliminado correctamente")),
      );
    } catch (e) {
      print("Error al eliminar equipo: $e");
    }
  }

  void _reenviarAMantenimiento(
      String equipoId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('equipos_mantenimiento').add({
        ...data,
        "fecha_reenvio": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('equipos_reparados')
          .doc(equipoId)
          .delete();
      await _registrarEnAuditoria(
          "Equipo reenviado a mantenimiento", equipoId, data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Equipo reenviado a mantenimiento")),
      );
    } catch (e) {
      print("Error al reenviar equipo a mantenimiento: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔧 Equipos Reparados"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
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
                  .collection('equipos_reparados')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay equipos reparados"));
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
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QrGeneratorScreen(data: data),
                          ),
                        );
                      },
                    );
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: ListTile(
                        leading: const Icon(Icons.build, color: Colors.green),
                        title: Text("${data['marca']} - ${data['modelo']}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Reparado por: ${data['tecnico']}"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "Eliminar") {
                              _eliminarEquipoReparado(equipo.id, data);
                            } else if (value == "Reenviar a mantenimiento") {
                              _reenviarAMantenimiento(equipo.id, data);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: "Reenviar a mantenimiento",
                                child: Text("🔄 Reenviar a mantenimiento")),
                            const PopupMenuItem(
                                value: "Eliminar",
                                child: Text("🗑 Eliminar equipo")),
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
    );
  }
}
