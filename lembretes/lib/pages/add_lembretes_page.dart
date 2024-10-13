import 'package:flutter/material.dart';

class AddLembreteScreen extends StatelessWidget {
  const AddLembreteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Lembrete'),
      ),
      body: const Center(
        child: Text('Adicionar Lembrete'),
      ),
    );
  }
}
