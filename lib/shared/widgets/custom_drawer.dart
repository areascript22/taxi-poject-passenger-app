import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:passenger_app/features/legal_info/view/pages/privacy_policy.dart';
import 'package:passenger_app/features/legal_info/view/pages/termns_and_conditions.dart';
import 'package:passenger_app/features/profile/view/pages/edit_profile_page.dart';
import 'package:passenger_app/features/ride_history/view/pages/ride_history_page.dart';
import 'package:passenger_app/features/ride_history/view/widgets/custom_devider.dart';
import 'package:passenger_app/features/settings/view/pages/settings_page.dart';

import 'package:passenger_app/features/technical_support/view/pages/technical_support.dart';
import 'package:passenger_app/shared/models/g_user.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
// import 'package:passenger_app/shared/repositories/push_notification_service.dart';
import 'package:passenger_app/shared/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedViewModel = Provider.of<SharedProvider>(context);
    GUser? passenger = sharedViewModel.passenger;

    return Drawer(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                //Header
                const SizedBox(height: 20),
                //UserData
                if (passenger != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              UserAvatar(imageUrl: passenger.profilePicture),

                              const SizedBox(width: 10),

                              // Passenger info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Passenger's name
                                    Text(
                                      passenger.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFFFDA503),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            passenger.ratings.rating.toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Forward icon
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          },
                          icon: const Icon(Ionicons.chevron_forward),
                        ),
                      ],
                    ),
                  ),
                const CustomDevider(),
                const SizedBox(height: 20),

                //Perfil
                ListTile(
                  leading: const Icon(Ionicons.time_outline),
                  title: const Text(
                    "Historial de solicitudes",
                    style: TextStyle(fontSize: 17),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RideHistoryPage(),
                        ));
                  },
                ),

                //COnfiguración
                ListTile(
                  leading: const Icon(Ionicons.settings_outline),
                  title: const Text(
                    "Configuración",
                    style: TextStyle(fontSize: 17),
                  ),
                  onTap: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ));
                  },
                ),

                //
                //Techinical support
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text(
                    "Soporte técnico",
                    style: TextStyle(fontSize: 17),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TechnicalSupport(),
                        ));
                  },
                ),

                //Termns and conditions
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text(
                    "Términos y condiciones",
                    style: TextStyle(fontSize: 17),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermnsAndConditionsPage(),
                        ));
                  },
                ),

                //Privacy policy
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text(
                    "Políticas de privacidad",
                    style: TextStyle(fontSize: 17),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyPage(),
                        ));
                  },
                ),
              ],
            ),

            //version
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('V ${sharedViewModel.version}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
