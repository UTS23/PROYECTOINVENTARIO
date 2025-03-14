import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EquiposBajaPage extends StatelessWidget {
  const EquiposBajaPage({Key? key}) : super(key: key);

  /// 🛑 Función para dar de baja un equipo con validación de email y contraseña
  void _darDeBajaEquipo(
      BuildContext context, String equipoId, Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString("userEmail");

    if (userEmail == null) {
      _mostrarSnackbar(context, "⚠️ Error: Usuario no identificado.");
      return;
    }

    TextEditingController passwordController = TextEditingController();
    TextEditingController razonController = TextEditingController();
    bool isButtonDisabled = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Confirmar Baja del Equipo"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Escribe la razón para dar de baja este equipo:"),
                  TextField(
                    controller: razonController,
                    decoration: const InputDecoration(
                      hintText: "Ejemplo: Equipo obsoleto",
                    ),
                    onChanged: (_) => setState(() {
                      isButtonDisabled = razonController.text.isEmpty ||
                          passwordController.text.isEmpty;
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Text("Ingrese su contraseña para confirmar:"),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: "Contraseña"),
                    onChanged: (_) => setState(() {
                      isButtonDisabled = razonController.text.isEmpty ||
                          passwordController.text.isEmpty;
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                          bool validado = await _validarUsuario(
                              userEmail, passwordController.text);
                          if (validado) {
                            await _moverEquipo(
                                context,
                                equipoId,
                                data,
                                "equipos_baja",
                                {"descripcion": razonController.text},
                                userEmail);
                            Navigator.pop(context);
                          } else {
                            _mostrarSnackbar(
                                context, "❌ Email o contraseña incorrecta.");
                          }
                        },
                  child: const Text("Confirmar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔐 Función para validar el email y la contraseña del usuario
  Future<bool> _validarUsuario(String userEmail, String password) async {
    try {
      QuerySnapshot usuarios = await FirebaseFirestore.instance
          .collection("usuarios")
          .where("email", isEqualTo: userEmail)
          .limit(1)
          .get();

      if (usuarios.docs.isNotEmpty) {
        String storedPassword = usuarios.docs.first.get("password") ?? "";
        return storedPassword == password;
      }
    } catch (e) {
      print("Error validando usuario: $e");
    }
    return false;
  }

  /// 🔄 Función para mover equipos entre colecciones y registrar en auditoría
  Future<void> _moverEquipo(
      BuildContext context,
      String equipoId,
      Map<String, dynamic> data,
      String nuevaColeccion,
      Map<String, dynamic> extraData,
      String userEmail) async {
    try {
      await FirebaseFirestore.instance.collection(nuevaColeccion).add({
        ...data, // Mantiene todos los datos originales
        ...extraData, // Agrega datos extra
        "fecha": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('equipos_mantenimiento')
          .doc(equipoId)
          .delete();

      await _registrarAuditoria(userEmail, data, extraData["descripcion"]);
      _mostrarSnackbar(context, "✅ Equipo dado de baja con éxito.");
    } catch (e) {
      _mostrarSnackbar(context, "❌ Error al dar de baja el equipo.");
      print("Error al mover el equipo: $e");
    }
  }

  /// 📜 Función para registrar la auditoría
  Future<void> _registrarAuditoria(
      String userEmail, Map<String, dynamic> data, String razon) async {
    try {
      await FirebaseFirestore.instance.collection('auditoria').add({
        "usuario": userEmail,
        "accion": "Dar de baja equipo",
        "equipo": "${data['marca']} - ${data['modelo']}",
        "fecha": FieldValue.serverTimestamp(),
        "razon": razon,
      });
    } catch (e) {
      print("Error registrando auditoría: $e");
    }
  }

  /// 📢 Función para mostrar un `Snackbar`
  void _mostrarSnackbar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📉 Equipos a Dar de Baja")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('equipos_baja').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay equipos a dar de baja"));
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
                  subtitle: Text("Razón de baja: ${data['descripcion']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _darDeBajaEquipo(context, equipo.id, data),
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
