import 'package:flutter/material.dart';

class CancelarSolicitud extends StatefulWidget {
  const CancelarSolicitud({super.key});

  @override
  State<CancelarSolicitud> createState() => _CancelarSolicitudState();
}

class _CancelarSolicitudState extends State<CancelarSolicitud> {
  double _scaleYes = 1.0;
  double _scaleNo = 1.0;

  void _animateButton(bool isYes) {
    setState(() {
      if (isYes) {
        _scaleYes = 1.2;
      } else {
        _scaleNo = 1.2;
      }
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _scaleYes = 1.0;
        _scaleNo = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '¿Cómo cancelar una carrera o encomienda?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          maxLines: 2,
        ),
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep('1. Cancelar una Carrera o Encomienda 📦',
                  'Si deseas cancelar una solicitud, la aplicación te ofrece dos opciones:'),
              _buildStep(' > Cancelar Petición ❌',
                  'Justo después de solicitar el servicio, la aplicación mostrará la opción de "Cancelar Petición" en la pantalla.'),
              _buildStep(' > Cancelar Viaje en Curso 🚗',
                  'Si el conductor ya ha aceptado la solicitud y está en camino, en la parte superior derecha de la pantalla aparecerá la opción de "Cancelar Viaje".'),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    const Text(
                      '¿La información fue útil?',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: _scaleNo,
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton(
                            onPressed: () => _animateButton(false),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            child: const Text('😞 No',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedScale(
                          scale: _scaleYes,
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton(
                            onPressed: () => _animateButton(true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            child: const Text('😊 Sí',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
