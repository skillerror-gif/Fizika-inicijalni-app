import 'package:flutter/material.dart';

import 'presentation/screens/home_screen.dart';

void main() => runApp(const FizikaApp());

class FizikaApp extends StatelessWidget {
  const FizikaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fizika',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: const GradeSelectionScreen(),
      );
}

class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Физика')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Изабери разред',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Вежбање, формативна провера и тестови знања.'),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.looks_one),
                title: const Text('I разред гимназије'),
                subtitle: const Text('Увод у физику и кинематика'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen(grade: 1)),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.looks_3),
                title: const Text('III разред гимназије'),
                subtitle: const Text('Магнетно поље • PASS база'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen(grade: 3)),
                ),
              ),
            ),
          ],
        ),
      );
}
