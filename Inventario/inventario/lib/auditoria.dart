import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({Key? key}) : super(key: key);

  @override
  _AuditoriaScreenState createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
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

  // 🔹 Función para generar y descargar el informe en PDF
  Future<void> _generarPDF(List<QueryDocumentSnapshot> cambios) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("📋 Informe de Auditoría",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Generado por: $usuarioActual",
                  style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["Fecha", "Acción", "Usuario", "Equipo", "Motivo"],
                data: cambios.map((cambio) {
                  var data = cambio.data() as Map<String, dynamic>;
                  String fecha =
                      (data['fecha'] as Timestamp?)?.toDate().toString() ??
                          "N/A";
                  return [
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.parse(fecha)),
                    data['accion'] ?? "Desconocido",
                    data['usuario'] ?? "Desconocido",
                    "${data['marca'] ?? 'N/A'} - ${data['modelo'] ?? 'N/A'}",
                    data['motivo'] ?? "N/A"
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getExternalStorageDirectory();
    final filePath = "${directory!.path}/Informe_Auditoria.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("📄 Informe guardado en: $filePath")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📋 Historial de Auditoría")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Usuario Actual:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(usuarioActual, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const Divider(),
          const Text(
            "Historial de Cambios:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('auditoria')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay registros."));
                }

                var cambios = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: cambios.length,
                  itemBuilder: (context, index) {
                    var cambio = cambios[index].data() as Map<String, dynamic>;

                    Timestamp? timestamp = cambio['fecha'] as Timestamp?;
                    String fecha = timestamp != null
                        ? DateFormat('dd/MM/yyyy HH:mm')
                            .format(timestamp.toDate())
                        : "Fecha no disponible";

                    String accion = cambio['accion'] ?? "Acción desconocida";
                    String usuario = cambio['usuario'] ?? "Usuario desconocido";
                    String marca = cambio['marca'] ?? "Marca desconocida";
                    String modelo = cambio['modelo'] ?? "Modelo desconocido";
                    String motivo = cambio['motivo'] ?? "Sin motivo";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.blue),
                        title: Text(accion,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📌 Equipo: $marca - $modelo"),
                            Text("👤 Usuario: $usuario"),
                            if (motivo.isNotEmpty) Text("📝 Motivo: $motivo"),
                            Text("📅 Fecha: $fecha"),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          var snapshot = await FirebaseFirestore.instance
              .collection('auditoria')
              .orderBy('fecha', descending: true)
              .get();
          await _generarPDF(snapshot.docs);
        },
        label: const Text("Descargar PDF"),
        icon: const Icon(Icons.download),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
