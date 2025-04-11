import 'package:flutter/material.dart';

class SolicitudTaxi extends StatefulWidget {
  const SolicitudTaxi({super.key});

  @override
  State<SolicitudTaxi> createState() => _SolicitudTaxiState();
}

class _SolicitudTaxiState extends State<SolicitudTaxi> {
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
          '¿Cómo solicitar un taxi?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          maxLines: 2,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep('1. Activar los Servicios de Ubicación 📍',
                  'Asegúrate de que los servicios de ubicación estén activados en tu dispositivo. Activa todos los permisos requeridos en la parte superior de la aplicación.'),
              _buildStep('2. Seleccionar el Tipo de Servicio 🚖',
                  'En la pantalla principal, elige entre "Encomiendas" o "Carreras". Para solicitar un taxi, selecciona "Carreras".'),
              _buildStep('3. Elegir el Método de Solicitud 🗺️🎙️✍️',
                  'Dentro de "Carreras", elige entre las opciones: "Por Mapa", "Por Audio" o "Por Texto". Recomendamos "Por Mapa" para mayor precisión.'),
              _buildStep('4. Confirmar la Ubicación ✅',
                  'Verifica que la ubicación mostrada en el mapa sea la correcta. Si es necesario, ajústala manualmente. Luego, presiona "Solicitar Taxi".'),
              _buildStep('5. Esperar la Aceptación del Viaje ⏳',
                  'Un conductor cercano aceptará tu solicitud. La aplicación mostrará su información y el tiempo estimado de llegada.'),
              _buildStep('6. Esperar la Llegada del Conductor 🚖',
                  'El conductor se dirigirá a tu ubicación. Puedes seguir su ruta en tiempo real dentro de la aplicación.'),
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
