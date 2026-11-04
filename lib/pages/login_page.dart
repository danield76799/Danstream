import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isXtream = true;
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthProvider>().credentials;
    if (saved != null) {
      _isXtream = saved.type == LoginType.xtream;
      if (saved.type == LoginType.xtream) {
        _serverController.text = saved.xtreamServer ?? '';
        _usernameController.text = saved.xtreamUsername ?? '';
        _passwordController.text = saved.xtreamPassword ?? '';
      } else {
        _m3uController.text = saved.m3uUrl ?? '';
      }
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final credentials = _isXtream
        ? ServerCredentials(
            type: LoginType.xtream,
            xtreamServer: _serverController.text.trim(),
            xtreamUsername: _usernameController.text.trim(),
            xtreamPassword: _passwordController.text.trim(),
          )
        : ServerCredentials(
            type: LoginType.m3u,
            m3uUrl: _m3uController.text.trim(),
          );

    await auth.saveCredentials(credentials);

    if (mounted && auth.error == null) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.live_tv,
                    size: 72,
                    color: Color(0xFF0DBD8B),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Danstream',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in met je M3U of Xtream Codes abonnement',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Xtream'),
                        icon: Icon(Icons.login),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('M3U'),
                        icon: Icon(Icons.list),
                      ),
                    ],
                    selected: {_isXtream},
                    onSelectionChanged: (value) {
                      setState(() => _isXtream = value.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_isXtream) ...[
                    TextField(
                      controller: _serverController,
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'https://jouwprovider.com:8080',
                        prefixIcon: Icon(Icons.dns),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Gebruikersnaam',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Wachtwoord',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                  ] else ...[
                    TextField(
                      controller: _m3uController,
                      decoration: const InputDecoration(
                        labelText: 'M3U URL',
                        hintText: 'https://jouwprovider.com/playlist.m3u',
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                  if (auth.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      auth.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.loading ? null : _login,
                    child: auth.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Inloggen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
