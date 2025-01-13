import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mny_mngm/model/provider.dart';
import 'package:mny_mngm/pages/HomePage.dart';
import 'package:mny_mngm/pages/TodayTask.dart';
import 'package:mny_mngm/pages/Show_History.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/explain.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChildNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '毎日成長',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BottomNavBar(),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    InputTaskPage(),
    TodayTaskPage(),
    RewardPage(),
    AccountPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: _pages[index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.help_outline_outlined),
                label: '使い方',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                activeIcon: Icon(Icons.business_center),
                label: 'リスト',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'やること',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'おこずかい',
              ),
            ],
            backgroundColor: const Color.fromARGB(255, 179, 179, 179),
            enableFeedback: true,
            iconSize: 18,
            selectedFontSize: 20,
            selectedIconTheme: const IconThemeData(
                size: 30, color: Color.fromARGB(255, 0, 0, 0)),
            selectedLabelStyle: const TextStyle(color: Colors.red),
            selectedItemColor: Colors.black,
            unselectedFontSize: 15,
            unselectedIconTheme: const IconThemeData(
                size: 25, color: Color.fromARGB(255, 255, 255, 255)),
            unselectedLabelStyle: const TextStyle(color: Colors.purple),
            unselectedItemColor: Colors.black,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline_outlined),
            label: '使い方',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            activeIcon: Icon(Icons.business_center),
            label: 'リスト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'やること',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'おこずかい',
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 179, 179, 179),
        enableFeedback: true,
        iconSize: 18,
        selectedFontSize: 20,
        selectedIconTheme:
            const IconThemeData(size: 30, color: Color.fromARGB(255, 0, 0, 0)),
        selectedLabelStyle: const TextStyle(color: Colors.red),
        selectedItemColor: Colors.black,
        unselectedFontSize: 15,
        unselectedIconTheme: const IconThemeData(
            size: 25, color: Color.fromARGB(255, 255, 255, 255)),
        unselectedLabelStyle: const TextStyle(color: Colors.purple),
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
