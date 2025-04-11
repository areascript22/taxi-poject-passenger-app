import 'package:flutter/material.dart';

class SolicitudEncomienda extends StatefulWidget {
  const SolicitudEncomienda({super.key});

  @override
  State<SolicitudEncomienda> createState() => _SolicitudEncomiendaState();
}

class _SolicitudEncomiendaState extends State<SolicitudEncomienda> {
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
          '¿Cómo solicitar una encomienda?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          maxLines: 2,
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep('1. Activar los Servicios de Ubicación 📍',
                  'Asegúrate de que los servicios de ubicación estén activados y concede los permisos requeridos.'),
              _buildStep('2. Acceder a la Sección de Encomiendas 📦',
                  'En la pantalla principal, selecciona la opción "Encomiendas".'),
              _buildStep('3. Elegir el Método de Ubicación 🗺️🎙️✍️',
                  'Selecciona entre "Por Mapa", "Por Audio" o "Por Texto" para establecer la ubicación de recolección.'),
              _buildStep('4. Ingresar los Detalles de la Encomienda ✏️',
                  'Introduce el nombre del destinatario y una descripción del paquete.'),
              _buildStep('5. Solicitar la Encomienda ✅',
                  'Presiona el botón "Solicitar Encomienda" para enviar la solicitud a los conductores disponibles.'),
              _buildStep('6. Confirmación y Espera del Conductor ⏳',
                  'Un conductor aceptará la solicitud y se dirigirá a la ubicación de recolección.'),
              _buildStep('7. Seguimiento y Entrega 🚚',
                  'Sigue la ruta de la encomienda en tiempo real hasta la entrega final.'),
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
