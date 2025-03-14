import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventario/qr_generator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EquiposNoReparadosPage extends StatefulWidget {
  const EquiposNoReparadosPage({Key? key}) : super(key: key);

  @override
  _EquiposNoReparadosPageState createState() => _EquiposNoReparadosPageState();
}

class _EquiposNoReparadosPageState extends State<EquiposNoReparadosPage> {
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

  void _mostrarDialogoEnvio(
      BuildContext context, String equipoId, Map<String, dynamic> data) {
    TextEditingController descripcionController = TextEditingController();
    String? destinoSeleccionado;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enviar equipo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: destinoSeleccionado,
                hint: const Text("Selecciona destino"),
                items: const [
                  DropdownMenuItem(
                      value: "equipos_baja", child: Text("Enviar a Baja")),
                  DropdownMenuItem(
                      value: "equipos_reparados", child: Text("Reparados")),
                ],
                onChanged: (value) {
                  destinoSeleccionado = value;
                },
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                    hintText: "Descripción de lo que se hizo"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                if (destinoSeleccionado != null &&
                    descripcionController.text.trim().isNotEmpty) {
                  _moverEquipo(equipoId, data, destinoSeleccionado!,
                      descripcionController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _moverEquipo(String equipoId, Map<String, dynamic> data,
      String destino, String descripcion) async {
    try {
      await FirebaseFirestore.instance.collection(destino).add({
        ...data,
        "descripcion": descripcion,
        "fecha": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('equipos_no_reparados')
          .doc(equipoId)
          .delete();

      await _registrarEnAuditoria("Equipo enviado a $destino", equipoId, data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Equipo enviado a $destino correctamente")),
      );
    } catch (e) {
      print("Error al mover el equipo: $e");
    }
  }

  Future<void> _restaurarEquipo(
      String equipoId, Map<String, dynamic> data) async {
    await _moverEquipo(
        equipoId, data, "equipos_reparados", "Restaurado correctamente");
  }

  Future<void> _eliminarEquipo(
      String equipoId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('equipos_no_reparados')
          .doc(equipoId)
          .delete();

      await _registrarEnAuditoria("Equipo eliminado", equipoId, data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Equipo eliminado correctamente")),
      );
    } catch (e) {
      print("Error al eliminar el equipo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("❌ Equipos No Reparados")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipos_no_reparados')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay equipos no reparados"));
          }

          final equipos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: equipos.length,
            itemBuilder: (context, index) {
              final equipo = equipos[index];
              final data = equipo.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${data['marca']} - ${data['modelo']}"),
                  subtitle: Text("Motivo: ${data['motivo']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_backup_restore,
                            color: Colors.green),
                        onPressed: () => _restaurarEquipo(equipo.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.vpn_key, color: Colors.blue),
                        onPressed: () =>
                            _mostrarDialogoEnvio(context, equipo.id, data),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _eliminarEquipo(equipo.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  QrGeneratorScreen(data: data),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
