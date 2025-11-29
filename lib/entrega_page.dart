import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'services/api_service.dart';
import 'mapa_page.dart';

class EntregaPage extends StatefulWidget {
  final Map<String, dynamic> paquete;

  EntregaPage({required this.paquete});

  @override
  _EntregaPageState createState() => _EntregaPageState();
}

class _EntregaPageState extends State<EntregaPage> {
  Uint8List? _fotoBytes;
  Position? _ubicacion;
  final picker = ImagePicker();
  bool enviando = false;

  Future<void> _tomarFoto() async {
    final foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() => _fotoBytes = bytes);
    }
  }

  Future<void> _obtenerUbicacion() async {
    try {
      Position posicion = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _ubicacion = posicion);
    } catch (e) {
      _mostrarError('Error obteniendo ubicación: $e');
    }
  }

  void _verMapa() {
    if (_ubicacion == null) {
      _mostrarError('Primero obtén la ubicación GPS');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaPage(
          latitud: _ubicacion!.latitude,
          longitud: _ubicacion!.longitude,
          direccion:
              widget.paquete['direccion_destino'] ?? 'Dirección no disponible',
        ),
      ),
    );
  }

  Future<void> _registrarEntrega() async {
    if (_fotoBytes == null || _ubicacion == null) {
      _mostrarError('Toma foto y obtén ubicación primero');
      return;
    }

    setState(() => enviando = true);

    try {
      String fotoBase64 = base64Encode(_fotoBytes!);

      print('📦 Enviando entrega...');
      print('ID Paquete: ${widget.paquete['id_paquete']}');
      print('Ubicación: ${_ubicacion!.latitude}, ${_ubicacion!.longitude}');

      final resultado = await ApiService.registrarEntrega({
        'id_paquete': widget.paquete['id_paquete'],
        'latitud': _ubicacion!.latitude,
        'longitud': _ubicacion!.longitude,
        'foto_evidencia': fotoBase64,
        'observaciones': 'Entregado con app móvil'
      });

      print('📡 Respuesta API: $resultado');

      if (resultado['success'] == true) {
        _mostrarExito(' Entrega registrada exitosamente');
        Navigator.pop(context);
      } else {
        _mostrarError(
            '❌ Error: ${resultado['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      print(' Error completo: $e');
      _mostrarError(' Error de conexión: $e');
    } finally {
      setState(() => enviando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Entrega')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Info del paquete
            Card(
              child: ListTile(
                title: Text(widget.paquete['codigo_seguimiento']?.toString() ??
                    'Sin código'),
                subtitle: Text(
                    widget.paquete['direccion_destino']?.toString() ??
                        'Sin dirección'),
              ),
            ),

            SizedBox(height: 20),

            // Foto
            _fotoBytes != null
                ? Image.memory(_fotoBytes!, height: 150)
                : Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: Icon(Icons.photo, size: 50)),

            ElevatedButton(
              onPressed: _tomarFoto,
              child: Text('Tomar Foto de Evidencia'),
            ),

            SizedBox(height: 20),

            // Ubicación
            _ubicacion != null
                ? Column(
                    children: [
                      Text(
                          '📍 Ubicación: ${_ubicacion!.latitude.toStringAsFixed(6)}, ${_ubicacion!.longitude.toStringAsFixed(6)}'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _verMapa,
                        child: Text(' Ver en Mapa'),
                      ),
                    ],
                  )
                : Text('Ubicación no obtenida'),

            ElevatedButton(
              onPressed: _obtenerUbicacion,
              child: Text(' Obtener Ubicación '),
            ),

            SizedBox(height: 20),

            // Botón entregar
            enviando
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registrarEntrega,
                    child: Text('📦 Paquete Entregado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
