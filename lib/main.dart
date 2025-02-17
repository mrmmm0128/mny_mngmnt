import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        ChangeNotifierProvider(create: (_) => ColorNotifier()),
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
        textTheme: GoogleFonts.coustardTextTheme(
          Theme.of(context).textTheme, // デフォルトのTextThemeに適用
        ),
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
  Color gradientEndColor = const Color(0xFFFEF9E7); // 初期色
  final List<Widget> _pages = [
    InputTaskPage(),
    TodayTaskPage(),
    RewardPage(),
    AccountPage(),
  ];
  late ColorNotifier colorNotifier; // ColorNotifierのインスタンス

  @override
  void initState() {
    super.initState();
    colorNotifier = Provider.of<ColorNotifier>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      colorNotifier.addListener(_onColorChanged);
    });
  }

  // 色が変更されたときに呼ばれる
  void _onColorChanged() {
    setState(() {}); // 色が変わったときに再描画
  }

  @override
  void dispose() {
    colorNotifier.removeListener(_onColorChanged);
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: _pages[index],
          bottomNavigationBar: Consumer<ColorNotifier>(
            builder: (context, colorNotifier, child) {
              return BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.business),
                    label: 'やること',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.school),
                    label: '今日',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.money),
                    label: 'おこづかい',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: '色変更',
                  ),
                ],
                backgroundColor: colorNotifier.gradientEndColor, // 色が即時に反映される
                enableFeedback: true,
                iconSize: 15,
                selectedFontSize: 17,
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
              );
            },
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
      bottomNavigationBar: Consumer<ColorNotifier>(
        builder: (context, colorNotifier, child) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'やること',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: '今日',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.money),
                label: 'おこづかい',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: '色変更',
              ),
            ],
            backgroundColor: colorNotifier.gradientEndColor, // 色が即時に反映される
            enableFeedback: true,
            iconSize: 15,
            selectedFontSize: 17,
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
          );
        },
      ),
    );
  }
}
