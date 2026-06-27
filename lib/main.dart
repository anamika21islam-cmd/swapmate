import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/all_items_screen.dart';
import 'screens/swap_items_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/message_screen.dart';
import 'screens/gift_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://qridchgklmajtmnyxcfn.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyaWRjaGdrbG1hanRtbnl4Y2ZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0OTA0MTUsImV4cCI6MjA5ODA2NjQxNX0.2dzbkmVgAk9kdPWAtt6Rm19GbsjughQoShOB5n0mXpk',
    );

    print("✅ Supabase Initialized Successfully");

    final supabase = Supabase.instance.client;
    await supabase.from('profiles').select().limit(1);

    print("✅ Database is fully connected and responded!");
  } catch (e) {
    print("ℹ️ Supabase Response Check: $e");
  }

  runApp(const SwapMateApp());
}

class SwapMateApp extends StatelessWidget {
  const SwapMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SwapMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AllItemsScreen(),
    const SwapItemsScreen(),
    const GiftScreen(),
    AddItemScreen(), // 🔥 const বাদ
    const MessageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'All Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Swap Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Gift',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add Item'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
        ],
      ),
    );
  }
}
