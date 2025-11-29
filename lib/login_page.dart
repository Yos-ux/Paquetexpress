import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool cargando = false;

  Future<void> _login() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      _mostrarError('Ingresa email y contraseña');
      return;
    }

    setState(() => cargando = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'email': emailCtrl.text.trim(), 'password': passCtrl.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final agente = data['agente'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(agente: agente),
          ),
        );
      } else {
        _mostrarError(data['message'] ?? 'Error en login');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.all(24),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Paquexpress',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(labelText: 'Email')),
                  SizedBox(height: 10),
                  TextField(
                      controller: passCtrl,
                      decoration: InputDecoration(labelText: 'Contraseña'),
                      obscureText: true),
                  SizedBox(height: 20),
                  cargando
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login, child: Text('Ingresar')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
