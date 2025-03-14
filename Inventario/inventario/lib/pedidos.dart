import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);

  @override
  _PedidosPageState createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _pedidosCollection =
      FirebaseFirestore.instance.collection('pedidos');
  final CollectionReference _equiposNuevosCollection =
      FirebaseFirestore.instance.collection('equipos_nuevos');

  Future<String?> _obtenerUsuarioEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  void _agregarPedido() async {
    try {
      TextEditingController marcaController = TextEditingController();
      TextEditingController modeloController = TextEditingController();
      TextEditingController precioController = TextEditingController();
      TextEditingController serialController = TextEditingController();
      String estado = "En espera";

      String? usuarioEmail = await _obtenerUsuarioEmail();
      if (usuarioEmail == null) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Agregar Pedido"),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(marcaController, "Marca"),
                  _buildTextField(modeloController, "Modelo"),
                  _buildTextField(precioController, "Precio",
                      inputType: TextInputType.number),
                  _buildTextField(serialController, "Serial"),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (marcaController.text.isNotEmpty &&
                      modeloController.text.isNotEmpty &&
                      precioController.text.isNotEmpty &&
                      serialController.text.isNotEmpty) {
                    await _pedidosCollection.add({
                      "marca": marcaController.text,
                      "modelo": modeloController.text,
                      "precio": precioController.text,
                      "serial": serialController.text,
                      "estado": estado,
                      "fecha": FieldValue.serverTimestamp(),
                      "agregadoPor": usuarioEmail,
                    });

                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Complete todos los campos")),
                    );
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error al abrir el diálogo de pedido: $e");
    }
  }

  void _actualizarEstado(String pedidoId, Map<String, dynamic> pedidoData,
      String nuevoEstado) async {
    try {
      String? usuarioEmail = await _obtenerUsuarioEmail();
      if (usuarioEmail == null) return;

      if (nuevoEstado == "Entregado") {
        // Copiar el pedido a la colección "equipos_nuevos"
        await _equiposNuevosCollection.add({
          "marca": pedidoData["marca"],
          "modelo": pedidoData["modelo"],
          "precio": pedidoData["precio"],
          "serial": pedidoData["serial"],
          "fechaIngreso": FieldValue.serverTimestamp(),
          "ingresadoPor": usuarioEmail,
        });

        // Eliminar el pedido de la colección "pedidos"
        await _pedidosCollection.doc(pedidoId).delete();
      } else {
        // Si no es "Entregado", solo actualizar el estado
        await _pedidosCollection.doc(pedidoId).update({
          "estado": nuevoEstado,
          "modificadoPor": usuarioEmail,
          "fechaModificacion": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error al actualizar el estado: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Pedidos"),
        backgroundColor: Colors.blue, // Color más oscuro
        actions: [
          TextButton.icon(
            onPressed: _agregarPedido,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Agregar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _pedidosCollection.orderBy("fecha", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No hay pedidos aún",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final pedidos = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: pedidos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final data = pedido.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${data["marca"]} - ${data["modelo"]}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Precio: \$${data["precio"]}",
                          style: const TextStyle(fontSize: 16)),
                      Text("Serial: ${data["serial"]}",
                          style: const TextStyle(fontSize: 16)),
                      Text(
                        "Estado: ${data["estado"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: data["estado"] == "En espera"
                              ? Colors.orange
                              : data["estado"] == "Recibido"
                                  ? Colors.blue
                                  : Colors.green,
                        ),
                      ),
                      if (data.containsKey("modificadoPor"))
                        Text(
                          "Última modificación por: ${data["modificadoPor"]}",
                          style: const TextStyle(
                              fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) {
                            _actualizarEstado(pedido.id, data, value);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: "En espera", child: Text("En espera")),
                            const PopupMenuItem(
                                value: "Recibido", child: Text("Recibido")),
                            const PopupMenuItem(
                                value: "Entregado", child: Text("Entregado")),
                          ],
                        ),
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

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: inputType,
    );
  }
}
