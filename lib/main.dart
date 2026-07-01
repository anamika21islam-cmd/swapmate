import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/chat_service.dart';

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
  } catch (e) {
    debugPrint("ℹ️ Supabase init error: $e");
  }

  // If a session already exists (persistent login), mark user as online
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    await ChatService().updatePresence(true);
  }

  runApp(const SwapMateApp());
}

class SwapMateApp extends StatelessWidget {
  const SwapMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SwapMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: session != null ? const DashboardWrapper() : const LoginScreen(),
    );
  }
}

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  final _supabase = Supabase.instance.client;
  final ChatService _chatService = ChatService();
  int _unreadCount = 0;
  final Set<String> _seenMessageIds = {};
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure online status is set when the dashboard loads
    _chatService.updatePresence(true);

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

  @override
  void dispose() {
    // Mark offline and clean up subscriptions when dashboard is torn down
    _chatService.updatePresence(false);
    _messageSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _chatService.updatePresence(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _chatService.updatePresence(false);
        break;
      case AppLifecycleState.inactive:
        // Don't change on inactive — it fires briefly during navigation
        break;
    }
  }

  void _listenForMessages() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _messageSubscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUserId)
        .listen((allMessages) {
          if (!mounted) return;

          final unread = allMessages
              .where((m) => m['is_read'] == false)
              .toList();

          setState(() {
            _unreadCount = unread.length;
          });

          for (final msg in unread) {
            final msgId = msg['id'] as String;
            final convId = msg['conversation_id'] as String;

            if (!_seenMessageIds.contains(msgId)) {
              _seenMessageIds.add(msgId);

              // Mark as delivered since the receiver's device got it
              final status = msg['status'] as String?;
              if (status == 'sent' || status == null) {
                _chatService.markMessageAsDelivered(msgId);
              }

              // Don't show snackbar if the user is already in that conversation
              if (ChatScreen.currentActiveConversationId != convId) {
                final text = msg['message'] ?? 'New message';
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('💬 $text'),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.teal.shade700,
                    ),
                  );
                }
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
