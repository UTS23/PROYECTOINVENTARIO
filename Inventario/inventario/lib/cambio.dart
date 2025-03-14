import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? loggedEmail;

  // Variables para mostrar/ocultar contraseñas
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadLoggedEmail();
  }

  // Carga el email del usuario desde SharedPreferences
  Future<void> _loadLoggedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedEmail = prefs.getString('userEmail');
    });
  }

  // Función para validar contraseñas (mínimo 6 caracteres y al menos 1 número)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingrese una contraseña";
    if (value.length < 6)
      return "La contraseña debe tener al menos 6 caracteres";
    if (!RegExp(r'\d').hasMatch(value))
      return "La contraseña debe contener al menos un número";
    return null;
  }

  // Función para actualizar la contraseña en la colección "usuarios"
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Verifica que la nueva contraseña no sea igual a la actual
    if (_newPasswordController.text == _currentPasswordController.text) {
      setState(() {
        _errorMessage = "La nueva contraseña no puede ser igual a la actual.";
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Las contraseñas nuevas no coinciden.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Consulta el documento del usuario basado en el email guardado
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: loggedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _errorMessage = "Usuario no encontrado.";
        });
      } else {
        DocumentSnapshot doc = query.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String storedPassword = data['password'] ?? "";

        // Verifica que la contraseña actual ingresada coincida con la almacenada
        if (_currentPasswordController.text != storedPassword) {
          setState(() {
            _errorMessage = "La contraseña actual es incorrecta.";
          });
          return;
        }

        // Actualiza el campo "password" en el documento del usuario
        await doc.reference.update({
          'password': _newPasswordController.text,
          // Opcional: puedes agregar un campo 'lastPasswordChange': FieldValue.serverTimestamp()
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contraseña actualizada exitosamente.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error al actualizar la contraseña: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cambiar Contraseña"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    // Campo para la contraseña actual
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: "Contraseña Actual",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureCurrent = !_obscureCurrent;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureCurrent,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Ingrese su contraseña actual";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo para la nueva contraseña
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: "Nueva Contraseña",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureNew,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    // Campo para confirmar la nueva contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: "Confirmar Nueva Contraseña",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirm,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Confirme la contraseña";
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _changePassword,
                              child: const Text("Actualizar Contraseña"),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
