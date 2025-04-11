import 'package:flutter/material.dart';

class HistorialDeCarreras extends StatefulWidget {
  const HistorialDeCarreras({super.key});

  @override
  State<HistorialDeCarreras> createState() => _HistorialDeCarrerasState();
}

class _HistorialDeCarrerasState extends State<HistorialDeCarreras> {
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
          '¿Cómo puedo ver mi historial de carreras?',
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
              _buildStep('1. Acceder a la Sección de Historial 📜',
                  'En la pantalla principal de la aplicación, selecciona la opción de menú en la parte superior izquierda, representada por el ícono de hamburguesa (tres líneas horizontales).'),
              _buildStep('2. Ver Perfil y Opciones 👤',
                  'Al hacer clic en el ícono de hamburguesa, se abrirá un menú con varias opciones, donde podrás ver tu nombre de usuario, tu foto y las opciones disponibles.'),
              _buildStep('3. Seleccionar Historial de Solicitudes 📋',
                  'En el menú, selecciona la opción "Historial de Solicitud", que es la primera opción en la lista. Esto te llevará a tu historial de viajes y encomiendas anteriores.'),
              _buildStep('4. Consultar el Historial de Solicitudes 📝',
                  'Una vez dentro del historial, verás una lista con los detalles de tus viajes pasados, incluyendo el nombre del cliente, ubicación inicial, destino, fecha y hora, y las coordenadas de cada solicitud.'),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    const Text(
                      '¿La información fue útil?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text('😞 No', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedScale(
                          scale: _scaleYes,
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton(
                            onPressed: () => _animateButton(true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            child: const Text('😊 Sí', style: TextStyle(color: Colors.white)),
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
