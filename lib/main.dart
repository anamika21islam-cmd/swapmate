import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/swap_items_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/message_screen.dart';
import 'screens/gift_screen.dart';
import 'screens/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://qridchgklmajtmnyxcfn.supabase.co',
      publishableKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyaWRjaGdrbG1hanRtbnl4Y2ZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0OTA0MTUsImV4cCI6MjA5ODA2NjQxNX0.2dzbkmVgAk9kdPWAtt6Rm19GbsjughQoShOB5n0mXpk',
    );

    debugPrint("✅ Supabase Initialized Successfully");

    final supabase = Supabase.instance.client;
    await supabase.from('profiles').select().limit(1);

    debugPrint("✅ Database is fully connected and responded!");
  } catch (e) {
    debugPrint("ℹ️ Supabase Response Check: $e");
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
  late final List<Widget> _screens;

  final _supabase = Supabase.instance.client;
  int _unreadCount = 0;
  final Set<String> _seenMessageIds = {};

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const SwapItemsScreen(),
      const GiftScreen(),
      AddItemScreen(
        onSaved: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
      const MessageScreen(),
    ];

    _listenForMessages();
  }

  void _listenForMessages() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUserId)
        .listen((allMessages) {
          if (!mounted) return;

          final messages = allMessages
              .where((m) => m['is_read'] == false)
              .toList();
          if (!mounted) return;

          setState(() {
            _unreadCount = messages.length;
          });

          for (final msg in messages) {
            final msgId = msg['id'] as String;
            final convId = msg['conversation_id'] as String;

            if (!_seenMessageIds.contains(msgId)) {
              _seenMessageIds.add(msgId);

              if (ChatScreen.currentActiveConversationId != convId) {
                final text = msg['message'] ?? 'New message';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New message: $text'),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            }
          }
        });
  }

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
        selectedFontSize: 11,
        unselectedFontSize: 10,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Swap Items',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Gift',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add Item',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.message),
                if (_unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Message',
          ),
        ],
      ),
    );
  }
}
