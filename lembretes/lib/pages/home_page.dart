import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lembretes/main.dart';
import 'package:lembretes/pages/login_page.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _lembrete;
  int _intervalo = 0;
  String _unidadeTempo = "";
  bool isNeverSelected = false;
  late Future<List<Map<String, dynamic>>> _lembretes;

  @override
  void initState() {
    super.initState();

    solicitarPermissaoNotificacoes();
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _lembretes = fetchLembretes(user.uid); // Inicializa a variável aqui
    }
  }

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

  Future<void> _submit(BuildContext context) async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == false) return;
    _formKey.currentState?.save();

    final User? user = _auth.currentUser;
    if (user == null) return;

    // Adicionar lembrete
    final Map<String, dynamic> data = {
      'title': _lembrete,
      'remember': isNeverSelected ? null : _intervalo,
      'remember_type': isNeverSelected ? 'nunca' : _unidadeTempo,
      'created_at': Timestamp.now(),
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('lembretes')
          .doc(user.uid)
          .collection('meus_lembretes')
          .add(data);

      // Agendar notificação
      if (!isNeverSelected) {
        // Converter a unidade de tempo para Duration
        Duration duration = calcularIntervalo(_intervalo, _unidadeTempo);

        // Agendar notificação
        Workmanager().registerPeriodicTask(
          "lembrete-${docRef.id}",
          "mostrar_notificacao",
          frequency: duration,
          inputData: <String, dynamic>{'lembreteTitle': _lembrete},
        );
      }

      // Recarregar a lista de lembretes
      setState(() {
        _lembretes = fetchLembretes(user.uid); // Atualiza a lista
      });

      // Mostra uma mensagem de sucesso
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lembrete salvo com sucesso!')),
        );

        Navigator.pop(context); // Fecha o dialog
      }
    } catch (e) {
      if (context.mounted) {
        // Trata erros de salvamento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar lembrete: $e')),
        );
      }
    }
  }

  Future<void> _delete(String documentId, BuildContext context) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    // Deletar lembrete
    try {
      await FirebaseFirestore.instance
          .collection('lembretes')
          .doc(user.uid)
          .collection('meus_lembretes')
          .doc(documentId)
          .delete();

      // Cancelar a notificação
      await cancelarNotificacao(documentId);

      // Recarregar a lista de lembretes
      setState(() {
        _lembretes = fetchLembretes(user.uid); // Atualiza a lista
      });

      if (context.mounted) {
        // Trata erros de exclusão
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lembrete excluído com sucesso!')),
        );

        Navigator.pop(context); // Fecha o dialog
      }
    } catch (e) {
      if (context.mounted) {
        // Trata erros de exclusão
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir lembrete: $e')),
        );
      }
    }
  }

  Widget _buildLembreteForm(bool isNeverSelected) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Lembrete'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Insira um nome para o lembrete';
              }
              return null;
            },
            onSaved: (newValue) {
              _lembrete = newValue;
            },
          ),
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: [
                  if (!isNeverSelected)
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Lembrar a cada'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Insira um intervalo de tempo válido';
                        }

                        final int intervalo = int.parse(value);
                        if (_unidadeTempo == 'minutos' && intervalo < 15) {
                          return 'O intervalo mínimo é de 15 minutos';
                        }

                        return null;
                      },
                      onSaved: (newValue) {
                        _intervalo = int.parse(newValue!);
                      },
                    ),
                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: 'Unidade de Tempo'),
                    items: const [
                      DropdownMenuItem<String>(
                          value: 'minutos', child: Text('Minutos')),
                      DropdownMenuItem<String>(
                          value: 'horas', child: Text('Horas')),
                      DropdownMenuItem<String>(
                          value: 'semanas', child: Text('Semanas')),
                      DropdownMenuItem<String>(
                          value: 'meses', child: Text('Meses')),
                      DropdownMenuItem<String>(
                          value: 'anos', child: Text('Anos')),
                      DropdownMenuItem<String>(
                          value: 'nunca', child: Text('Nunca lembrar')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        isNeverSelected = value == 'nunca';
                        _unidadeTempo = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione uma unidade de tempo';
                      }
                      return null;
                    },
                    onSaved: (newValue) {
                      _unidadeTempo = newValue!;
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Duration calcularIntervalo(int intervalo, String unidade) {
    switch (unidade) {
      case 'minutos':
        return Duration(minutes: intervalo);
      case 'horas':
        return Duration(hours: intervalo);
      case 'semanas':
        return Duration(days: intervalo * 7);
      case 'meses':
        return Duration(days: intervalo * 30); // Aproximação
      case 'anos':
        return Duration(days: intervalo * 365); // Aproximação
      default:
        return Duration.zero;
    }
  }

  Future<void> cancelarNotificacao(String lembreteId) async {
    await Workmanager().cancelByUniqueName("lembrete-$lembreteId");
  }

  Future<void> solicitarPermissaoExata() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> solicitarPermissaoNotificacoes() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> agendarLembrete(
      String lembreteId, String title, int intervalo, String unidade) async {
    // Verifica a permissão para alarmes exatos
    if (await Permission.scheduleExactAlarm.isDenied) {
      await solicitarPermissaoExata();
    }

    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    final intervaloDuration = calcularIntervalo(intervalo, unidade);
    final scheduleTime = DateTime.now().add(intervaloDuration);
    final tzDateTime = tz.TZDateTime.from(scheduleTime, tz.local);

    // Configuração do canal de notificações (som, prioridade, importância)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'lembrete_channel', // Este ID deve ser único para o canal
      'Lembretes', // Nome do canal
      channelDescription: 'Canal para lembretes agendados',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Para a programação de notificação
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        lembreteId.hashCode,
        'Lembretes',
        title,
        tzDateTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
      print('Notificação agendada com sucesso!');
      print('Notificação agendada para $tzDateTime');
    } catch (e) {
      print('Erro ao agendar notificação: $e');
    }
  }

  void _addLembreteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Lembrete'),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildLembreteForm(isNeverSelected),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => _submit(context),
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _viewLembrete(lembretes, index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lembretes[index]['title'] ?? ''),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ajusta o tamanho da coluna
            children: [
              Text(lembretes[index]['description'] ?? ''),
              Text(
                lembretes[index]['remember'] != null
                    ? 'Lembrar a cada: ${lembretes[index]['remember']} ${lembretes[index]['remember_type']}'
                    : '',
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => _delete(lembretes[index]['id'], context),
              child: const Text('Excluir'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchLembretes(String userId) async {
    final firestore = FirebaseFirestore.instance;

    final querySnapshot = await firestore
        .collection('lembretes')
        .doc(userId)
        .collection('meus_lembretes')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Adiciona o ID do documento aos dados
      return data;
    }).toList();
  }

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
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _lembretes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar lembretes.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Nenhum lembrete encontrado.'));
            }

            // Exibe a lista de lembretes em formato de card
            final lembretes = snapshot.data!;
            return ListView.builder(
              itemCount: lembretes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(lembretes[index]['title'] ?? ''),
                    onTap: () => _viewLembrete(lembretes, index),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addLembreteDialog(context),
          child: const Icon(Icons.add),
        ));
  }
}
