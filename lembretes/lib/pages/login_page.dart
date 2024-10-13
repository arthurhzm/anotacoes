import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLogin = true;

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == true) {
      _formKey.currentState?.save();
      try {
        if (_isLogin) {
          // Login
          await _auth.signInWithEmailAndPassword(
              email: _email, password: _password);
        } else {
          // Registro
          await _auth.createUserWithEmailAndPassword(
              email: _email, password: _password);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Ocorreu um erro, tente novamente.';
        // Tratamento de erros comuns
        if (e.code == 'user-not-found') {
          errorMessage = 'Usuário não encontrado. Por favor, registre-se.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Senha incorreta. Tente novamente.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Este e-mail já está registrado. Tente fazer login.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'O e-mail inserido é inválido.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'A senha é muito fraca. Escolha uma senha mais forte.';
        }

        // Exibe a mensagem de erro usando um SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Registrar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Insira um email válido';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _email = value ?? '';
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value ?? '';
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Login' : 'Registrar')),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin
                      ? 'Criar uma conta'
                      : 'Já tem uma conta? Faça login'),
                )
              ],
            )),
      ),
    );
  }
}
