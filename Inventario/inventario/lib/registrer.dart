import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventario/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;

  bool _isLoading = false;

  // Método para encriptar la contraseña
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _register() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String phone = _phoneController.text.trim();
    String profession = _professionController.text.trim();
    String address = _addressController.text.trim();
    String document = _documentController.text.trim();
    String birthDate =
        _selectedDate != null ? _selectedDate!.toIso8601String() : "";

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        phone.isEmpty ||
        profession.isEmpty ||
        address.isEmpty ||
        document.isEmpty ||
        birthDate.isEmpty ||
        _selectedGender == null) {
      _showMessage("Todos los campos son obligatorios");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Las contraseñas no coinciden");
      return;
    }

    setState(() => _isLoading = true);

    try {
      var userExists = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .get();

      if (userExists.docs.isNotEmpty) {
        _showMessage("Este correo ya está registrado");
      } else {
        await FirebaseFirestore.instance.collection('usuarios').add({
          'name': name,
          'email': email,
          'password': _hashPassword(password),
          'phone': phone,
          'profession': profession,
          'address': address,
          'document': document,
          'birthDate': birthDate,
          'gender': _selectedGender,
          'createdAt': Timestamp.now(),
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    }

    setState(() => _isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _register();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage("Nombre Completo", _nameController, Icons.person),
                  _buildPage("Teléfono", _phoneController, Icons.phone),
                  _buildPage("Dirección", _addressController, Icons.home),
                  _buildPage("Profesión", _professionController, Icons.work),
                  _buildPage("Documento de Identidad", _documentController,
                      Icons.badge),
                  _buildDatePickerPage(),
                  _buildGenderSelection(),
                  _buildPage(
                      "Correo Electrónico", _emailController, Icons.email),
                  _buildPage("Contraseña", _passwordController, Icons.lock,
                      obscureText: true),
                  _buildPage("Confirmar Contraseña", _confirmPasswordController,
                      Icons.lock,
                      obscureText: true),
                ],
              ),
            ),
            _isLoading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        ElevatedButton(
                          onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut),
                          child: const Text("Atrás"),
                        ),
                      ElevatedButton(
                        onPressed: _nextPage,
                        child:
                            Text(_currentPage == 9 ? "Registrar" : "Siguiente"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
      String label, TextEditingController controller, IconData icon,
      {bool obscureText = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.deepPurple),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today, size: 80, color: Colors.deepPurple),
        const SizedBox(height: 20),
        Text(
          _selectedDate == null
              ? "Selecciona tu fecha de nacimiento"
              : "Fecha: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _selectDate(context),
          child: const Text("Seleccionar Fecha"),
        ),
      ],
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wc, size: 80, color: Colors.deepPurple),
        const SizedBox(height: 20),
        const Text("Selecciona tu género"),
        DropdownButton<String>(
          value: _selectedGender,
          items: ["Masculino", "Femenino", "Otro"]
              .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
        ),
      ],
    );
  }
}
