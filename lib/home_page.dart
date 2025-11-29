import 'package:flutter/material.dart';
import 'paquetes_page.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic> agente;

  HomePage({required this.agente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paquetes Asignados'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: PaquetesPage(agenteId: agente['id_agente']),
    );
  }
}
