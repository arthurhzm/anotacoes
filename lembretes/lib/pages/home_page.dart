import 'package:flutter/material.dart';
import 'package:lembretes/pages/add_lembretes_page.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<Map<String, String>> lembretes = [
    {
      'title': 'Tomar água',
      'description': 'Beber água a cada 1 hora para se manter hidratado.',
      'remember': '1 hora'
    },
    {
      'title': 'Ler artigo',
      'description': 'Ler o artigo sobre Flutter no Medium.',
      'remember': '1 dia'
    },
    {
      'title': 'Exercício físico',
      'description': 'Fazer 30 minutos de exercício físico diariamente.',
      'remember': 'Nunca'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Meus Lembretes'),
        ),
        body: ListView.builder(
          itemCount: lembretes.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(lembretes[index]['title'] ?? ''),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(lembretes[index]['title'] ?? ''),
                          content: Column(
                            children: [
                              Text(lembretes[index]['description'] ?? ''),
                              Text(
                                  'Lembrar a cada: ${lembretes[index]['remember'] ?? ''}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Fechar'),
                            )
                          ],
                        );
                      });
                },
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddLembreteScreen()));
          },
          child: const Icon(Icons.add),
        ));
  }
}
