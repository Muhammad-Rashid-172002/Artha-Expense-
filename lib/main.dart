import 'package:expanse_tracker_app/Screens/Splash_Screen/Splash_Screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Splashscreen(),
    );
  }
}
//  Card(
//                             margin: const EdgeInsets.only(bottom: 20),
//                             color: Colors.grey[850],
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                               side: BorderSide(
//                                 color: Colors.white, // Border color
//                                 width: 2, // Border width
//                               ),
//                             ),
//                             elevation: 4,
//                             child: Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     DateFormat(
//                                       'MMMM yyyy',
//                                     ).format(DateTime.now()),
//                                     style: const TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 10),
//                                   Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceAround,
//                                     children: List.generate(7, (index) {
//                                       final today = DateTime.now();
//                                       final startOfWeek = today.subtract(
//                                         Duration(days: today.weekday - 1),
//                                       );
//                                       final currentDay = startOfWeek.add(
//                                         Duration(days: index),
//                                       );
//                                       final daysOfWeek = [
//                                         'Mon',
//                                         'Tue',
//                                         'Wed',
//                                         'Thu',
//                                         'Fri',
//                                         'Sat',
//                                         'Sun',
//                                       ];
//                                       final isToday =
//                                           today.day == currentDay.day &&
//                                           today.month == currentDay.month &&
//                                           today.year == currentDay.year;
//                                       return Column(
//                                         children: [
//                                           Text(
//                                             daysOfWeek[index],
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 6),
//                                           CircleAvatar(
//                                             radius: 16,
//                                             backgroundColor: isToday
//                                                 ? Colors.white
//                                                 : Colors.transparent,
//                                             child: Text(
//                                               '${currentDay.day}',
//                                               style: TextStyle(
//                                                 color: isToday
//                                                     ? Colors.amber
//                                                     : Colors.white,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       );
//                                     }),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
                       