import 'package:flutter/material.dart';
import 'entrega_page.dart';
import 'services/api_service.dart';

class PaquetesPage extends StatefulWidget {
  final int agenteId;
  PaquetesPage({required this.agenteId});
  @override
  _PaquetesPageState createState() => _PaquetesPageState();
}

class _PaquetesPageState extends State<PaquetesPage> {
  List<dynamic> paquetes = [];
  bool cargando = true;
  String mensajeError = '';

  @override
  void initState() {
    super.initState();
    _cargarPaquetes();
  }

  Future<void> _cargarPaquetes() async {
    try {
      final response = await ApiService.getPaquetesAsignados(widget.agenteId);

      if (response is List) {
        setState(() {
          paquetes = response;
          cargando = false;
          mensajeError = paquetes.isEmpty ? 'No hay paquetes asignados' : '';
        });
      } else {
        setState(() {
          cargando = false;
          mensajeError = 'Error: La API no devolvió una lista válida';
        });
      }
    } catch (e) {
      setState(() {
        cargando = false;
        mensajeError = 'Error cargando paquetes: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Center(child: CircularProgressIndicator());
    }

    if (mensajeError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 50, color: Colors.red),
            SizedBox(height: 10),
            Text(mensajeError, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cargarPaquetes,
              child: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: paquetes.length,
      itemBuilder: (context, index) {
        final paquete = paquetes[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            leading: Icon(Icons.local_shipping, color: Colors.blue),
            title:
                Text(paquete['codigo_seguimiento']?.toString() ?? 'Sin código'),
            subtitle: Text(
                paquete['direccion_destino']?.toString() ?? 'Sin dirección'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EntregaPage(paquete: paquete)),
              );
            },
          ),
        );
      },
    );
  }
}
