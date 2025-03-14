import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class QrGeneratorScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const QrGeneratorScreen({Key? key, required this.data}) : super(key: key);

  @override
  _QrGeneratorScreenState createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _guardarQR() async {
    // Solicita permiso de almacenamiento
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permiso denegado para escribir en el almacenamiento'),
        ),
      );
      return;
    }

    try {
      // Espera un poco para asegurar que el widget se renderice
      final image = await screenshotController.capture(
        delay: const Duration(milliseconds: 300),
      );
      if (image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al capturar la imagen')),
        );
        return;
      }

      // Usamos getApplicationDocumentsDirectory para mayor compatibilidad
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(image);

      // Imprime la ruta en la consola para verificar
      print('QR guardado en: $filePath');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR guardado en: $filePath')),
      );
    } catch (e) {
      print('Error guardando el QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando el QR: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String qrData =
        "Marca: ${widget.data['marca']}\nModelo: ${widget.data['modelo']}\nEstado: ${widget.data['estado']}\nFecha: ${DateTime.now()}";

    return Scaffold(
      appBar: AppBar(title: const Text("Código QR del Equipo")),
      body: Center(
        child: Screenshot(
          controller: screenshotController,
          child: QrImageView(
            data: qrData,
            size: 250,
            backgroundColor: Colors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _guardarQR,
        child: const Icon(Icons.download),
      ),
    );
  }
}
