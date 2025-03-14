import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventario/qr_generator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EquiposMantenimientoPage extends StatelessWidget {
  const EquiposMantenimientoPage({Key? key}) : super(key: key);

  void _mostrarDialogoAprobacion(
      BuildContext context, String equipoId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Aprobar equipo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("¿Quieres aprobar este equipo y enviarlo a disponibles?"),
              const SizedBox(height: 10),
              Text("Marca: ${data['marca']}"),
              Text("Modelo: ${data['modelo']}"),
              Text("Estado actual: ${data['estado']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                _aprobarEquipo(context, equipoId, data);
                Navigator.pop(context);
              },
              child: const Text("Aprobar ✅"),
            ),
            TextButton(
              onPressed: () {
                _desaprobarEquipo(context, equipoId, data);
                Navigator.pop(context);
              },
              child: const Text("Desaprobar ❌"),
            ),
          ],
        );
      },
    );
  }

  void _aprobarEquipo(
      BuildContext context, String equipoId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('equipos_disponibles').add({
        "marca": data["marca"],
        "modelo": data["modelo"],
        "estado": "Disponible",
        "fecha": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('equipos_mantenimiento')
          .doc(equipoId)
          .delete();

      await _registrarMovimiento(
          equipoId, data, "Aprobado y enviado a disponibles");

      _mostrarSnackbar(context, "✅ Equipo aprobado y enviado a disponibles.");
    } catch (e) {
      _mostrarSnackbar(context, "❌ Error al aprobar el equipo.");
      print("Error al aprobar el equipo: $e");
    }
  }

  void _desaprobarEquipo(
      BuildContext context, String equipoId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('equipos_no_reparados').add({
        "marca": data["marca"],
        "modelo": data["modelo"],
        "estado": "No Reparado",
        "fecha": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('equipos_mantenimiento')
          .doc(equipoId)
          .delete();

      await _registrarMovimiento(
          equipoId, data, "Desaprobado y enviado a no reparados");

      _mostrarSnackbar(
          context, "❌ Equipo desaprobado y enviado a no reparados.");
    } catch (e) {
      _mostrarSnackbar(context, "❌ Error al desaprobar el equipo.");
      print("Error al desaprobar el equipo: $e");
    }
  }

  Future<void> _registrarMovimiento(
      String equipoId, Map<String, dynamic> data, String accion) async {
    await FirebaseFirestore.instance.collection('historial_movimientos').add({
      "equipoId": equipoId,
      "marca": data["marca"],
      "modelo": data["modelo"],
      "accion": accion,
      "fecha": FieldValue.serverTimestamp(),
    });
  }

  void _mostrarSnackbar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _verDetallesEquipo(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Detalles del Equipo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Marca: ${data['marca']}"),
              Text("Modelo: ${data['modelo']}"),
              Text("Estado: ${data['estado']}"),
              Text("Fecha de ingreso: ${data['fecha'] ?? 'Desconocida'}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🛠 Equipos en Mantenimiento")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipos_mantenimiento')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay equipos en mantenimiento"));
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
                  subtitle: Text("Estado: ${data['estado']}"),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info, color: Colors.orange),
                        onPressed: () {
                          _verDetallesEquipo(context, data);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.build, color: Colors.blue),
                        onPressed: () {
                          _mostrarDialogoAprobacion(context, equipo.id, data);
                        },
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
