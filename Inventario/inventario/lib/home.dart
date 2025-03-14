import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventario/login.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:inventario/inventario.dart';
import 'package:inventario/pedidos.dart';
import 'package:inventario/confi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String? loggedEmail;
  String? truncatedName;
  String? ipAddress = "Obteniendo IP...";
  String? location = "Obteniendo ubicación...";

  @override
  void initState() {
    super.initState();
    _loadLoggedEmailAndName();
    _getUserLocation();
    _getPublicIPAddress();
  }

  Future<void> _loadLoggedEmailAndName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    setState(() {
      loggedEmail = email;
    });

    if (email != null) {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        Map<String, dynamic> data =
            query.docs.first.data() as Map<String, dynamic>;
        String name = data['name'] ?? "Usuario";
        String tName = name.length > 8 ? name.substring(0, 8) : name;
        setState(() {
          truncatedName = tName;
        });
      }
    }
  }

  Future<void> _getPublicIPAddress() async {
    try {
      final response =
          await http.get(Uri.parse('https://api64.ipify.org?format=json'));
      if (response.statusCode == 200) {
        String ip = json.decode(response.body)['ip'];
        setState(() {
          ipAddress = "IP: $ip";
        });
      } else {
        setState(() {
          ipAddress = "No se pudo obtener la IP";
        });
      }
    } catch (e) {
      setState(() {
        ipAddress = "Error al obtener la IP";
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          location = "Ubicación desactivada";
        });
        print("Error: Servicios de ubicación desactivados.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          setState(() {
            location = "Permiso de ubicación denegado";
          });
          print("Error: Permiso de ubicación denegado permanentemente.");
          return;
        } else if (permission == LocationPermission.denied) {
          setState(() {
            location = "Permiso de ubicación denegado temporalmente";
          });
          print("Error: Permiso de ubicación denegado.");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        location = "Lat: ${position.latitude}, Lon: ${position.longitude}";
      });
      print("Ubicación obtenida correctamente: $location");
    } catch (e) {
      setState(() {
        location = "Conexion ";
      });
      print("Error en _getUserLocation: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "UTS",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 5,
        shadowColor: Colors.black26,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (truncatedName != null)
                  Text(
                    truncatedName!,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                Text(
                  ipAddress!,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
                Text(
                  location!,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: const [
          InventarioPage(),
          PedidosPage(),
          ConfiguracionPage(),
        ],
      ),
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Colors.blue,
        style: TabStyle.react,
        items: const [
          TabItem(icon: Icons.inventory_2, title: "Inventario"),
          TabItem(icon: Icons.shopping_cart, title: "Pedidos"),
          TabItem(icon: Icons.settings, title: "Configuración"),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
