import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/presentation/main_shell.dart';

class AanchalBoutiqueApp extends StatelessWidget {
  const AanchalBoutiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
