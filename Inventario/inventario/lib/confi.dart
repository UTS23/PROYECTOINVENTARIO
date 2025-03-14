import 'package:flutter/material.dart';
import 'package:inventario/InformacionPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventario/login.dart';
import 'package:inventario/auditoria.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ Configuración")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Información Personal"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InformacionPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.admin_panel_settings, color: Colors.green),
              title: const Text("Crear Cuenta Admin"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Implementación de crear cuenta admin
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.orange),
              title: const Text("Auditoría"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AuditoriaScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
