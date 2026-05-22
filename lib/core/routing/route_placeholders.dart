import 'package:flutter/material.dart';

/// Widgets temporales hasta implementar las pantallas en cada feature.
/// No sustituyen la UI final; solo permiten probar el ruteo.
class RoutePlaceholder extends StatelessWidget {
  const RoutePlaceholder({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(label)),
    );
  }
}
