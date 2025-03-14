import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventario/cambio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/login.dart';

import 'package:intl/intl.dart';

class InformacionPage extends StatefulWidget {
  const InformacionPage({Key? key}) : super(key: key);

  @override
  _InformacionPageState createState() => _InformacionPageState();
}

class _InformacionPageState extends State<InformacionPage> {
  String? loggedEmail;
  String? docId;
  Map<String, dynamic>? userData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadLoggedEmail();
  }

  // Carga el email del usuario logueado desde SharedPreferences
  Future<void> _loadLoggedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedEmail = prefs.getString('userEmail');
    });
  }

  // Actualiza los datos en Firestore (solo los campos editables)
  Future<void> _updateUserData() async {
    if (docId != null) {
      final updatedData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'profession': _professionController.text,
      };
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(docId)
          .update(updatedData);
      // Opcional: mostrar una notificación breve
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados')),
      );
    }
  }

  // Debounce para evitar múltiples escrituras en Firestore en cada cambio
  void _onFieldChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _updateUserData();
    });
  }

  // Función para cerrar sesión
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mientras se carga el email del usuario, mostramos un indicador de carga.
    if (loggedEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Información de Usuario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      // Se consulta en Firestore solo el documento del usuario logueado (filtrando por email)
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('email', isEqualTo: loggedEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay usuarios registrados"));
          }

          // Se espera que la consulta devuelva solo un documento (el del usuario logueado)
          final docSnapshot = snapshot.data!.docs.first;
          docId = docSnapshot.id;
          userData = docSnapshot.data() as Map<String, dynamic>;

          // Establece los valores iniciales de los controladores si aún no están llenos.
          if (_nameController.text.isEmpty) {
            _nameController.text = userData?['name'] ?? "";
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = userData?['phone'] ?? "";
          }
          if (_professionController.text.isEmpty) {
            _professionController.text = userData?['profession'] ?? "";
          }

          final formattedCreationDate = userData?['createdAt'] != null
              ? DateFormat('dd MMMM yyyy, hh:mm:ss a')
                  .format(userData?['createdAt'].toDate())
              : "No disponible";

          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Campo para el nombre (editable)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Nombre",
                          icon: Icon(Icons.person),
                        ),
                        onChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 10),
                      // Campo para el email (solo lectura)
                      TextFormField(
                        initialValue: userData?['email'] ?? "No disponible",
                        decoration: const InputDecoration(
                          labelText: "Email",
                          icon: Icon(Icons.email),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      // Campo para el teléfono (editable)
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: "Teléfono",
                          icon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 10),
                      // Campo para la profesión (editable)
                      TextFormField(
                        controller: _professionController,
                        decoration: const InputDecoration(
                          labelText: "Profesión",
                          icon: Icon(Icons.work),
                        ),
                        onChanged: _onFieldChanged,
                      ),
                      const SizedBox(height: 10),
                      // Fecha de creación (solo lectura)
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title:
                            Text("Fecha de Creación: $formattedCreationDate"),
                      ),
                      const Divider(),
                      // Ícono de llave que redirige a la pantalla para cambiar la contraseña
                      ListTile(
                        leading: const Icon(Icons.vpn_key, color: Colors.blue),
                        title: const Text("Cambiar contraseña"),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
