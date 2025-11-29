import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  static Future<dynamic> getPaquetesAsignados(int agenteId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/paquetes/asignados/$agenteId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Error HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error en getPaquetesAsignados: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> registrarEntrega(
      Map<String, dynamic> datos) async {
    final response = await http.post(
      Uri.parse('$baseUrl/entregas/registrar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    return jsonDecode(response.body);
  }
}
