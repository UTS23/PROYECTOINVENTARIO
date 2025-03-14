import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_generator_screen.dart'; // Asegúrate de tener este widget implementado

class EquiposNuevosPage extends StatelessWidget {
  const EquiposNuevosPage({Key? key}) : super(key: key);

  Future<void> moverAEquiposDisponibles(
      BuildContext context, DocumentSnapshot equipo) async {
    final data = equipo.data() as Map<String, dynamic>;

    // Obtener usuario actual de SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioActual =
        prefs.getString('userEmail') ?? "Usuario desconocido";

    // Registrar movimiento en auditoría
    await FirebaseFirestore.instance.collection('auditoria').add({
      'accion': 'Movimiento de equipo',
      'marca': data['marca'] ?? 'Desconocido',
      'modelo': data['modelo'] ?? 'Desconocido',
      'usuario': usuarioActual,
      'fecha': FieldValue.serverTimestamp(),
      'motivo': 'Cambio de estado a Funcionando'
    });

    // Mover equipo a la colección 'equipos_disponibles'
    await FirebaseFirestore.instance
        .collection('equipos_disponibles')
        .add({...data, 'estado': 'Funcionando'});

    // Eliminar equipo de 'equipos_nuevos'
    await FirebaseFirestore.instance
        .collection('equipos_nuevos')
        .doc(equipo.id)
        .delete();

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "✅ Equipo ${data['marca']} - ${data['modelo']} movido correctamente"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Equipos Nuevos"),
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('equipos_nuevos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No hay equipos nuevos disponibles",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            );
          }

          final equipos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: equipos.length,
            itemBuilder: (context, index) {
              final equipo = equipos[index];
              final data = equipo.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading:
                      const Icon(Icons.devices_other, color: Colors.deepPurple),
                  title: Text(
                    "${data['marca'] ?? 'Desconocida'} - ${data['modelo'] ?? 'Desconocido'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "💲 Precio: \$${data['precio'] ?? 'No disponible'}",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón para generar el código QR
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
                      // Botón para mover el equipo a 'equipos_disponibles'
                      IconButton(
                        icon: const Icon(Icons.move_to_inbox,
                            color: Colors.green),
                        onPressed: () =>
                            moverAEquiposDisponibles(context, equipo),
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
