import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import 'live_tv_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final credentials = context.read<AuthProvider>().credentials;
    if (credentials != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<CatalogProvider>().loadCatalog(credentials);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danstream'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: catalog.loading
          ? const Center(child: CircularProgressIndicator())
          : catalog.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      catalog.error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : IndexedStack(
                  index: _currentIndex,
                  children: const [
                    LiveTvPage(),
                    Center(child: Text('Films')),
                    Center(child: Text('Series')),
                  ],
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv),
            label: 'Live TV',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie),
            label: 'Films',
          ),
          NavigationDestination(
            icon: Icon(Icons.tv),
            label: 'Series',
          ),
        ],
      ),
    );
  }
}
