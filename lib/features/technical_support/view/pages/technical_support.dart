import 'package:flutter/material.dart';
import 'package:passenger_app/features/technical_support/view/pages/technical_support_content.dart';
import 'package:passenger_app/features/technical_support/viewmodel/technical_support_viewmodel.dart';
import 'package:provider/provider.dart';

class TechnicalSupport extends StatelessWidget {
  const TechnicalSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TechnicalSupportViewModel(),
      child: const TechnicalSupportContent(),
    );
  }
}
