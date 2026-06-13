import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../shared/widgets.dart';

PreferredSizeWidget buildRoleAppBar(String title, BuildContext context) {
  return AppBar(
    title: Text(title),
    actions: [
      const AppSettingsActions(),
      Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return TextButton.icon(
            onPressed: () {
              auth.logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          );
        },
      ),
    ],
  );
}
