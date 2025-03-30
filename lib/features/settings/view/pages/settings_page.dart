import 'package:flutter/material.dart';
import 'package:passenger_app/features/settings/view/pages/settings_page_content.dart';
import 'package:passenger_app/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsViewModel(),
      child: const SettingsPageContent(),
      
    );
  }
}
