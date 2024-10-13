import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lembretes/pages/add_lembretes_page.dart';
import 'package:lembretes/pages/login_page.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Logout
  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

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
          title: const Text('Lembretes'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Logout'),
                onTap: () => _signOut(context),
              ),
            ],
          ),
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
