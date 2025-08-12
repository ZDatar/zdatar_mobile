import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zdatar_mobile/screens/wallet_page.dart';
import 'models/app_state.dart';
import 'screens/home_page.dart';
import 'screens/my_data_page.dart';
import 'screens/market_place_page.dart';
import 'theme/app_theme.dart';
import 'screens/profile_page.dart';
import 'screens/notification_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Namer App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            home: MyHomePage(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 2; // Start with Home selected

  @override
  Widget build(BuildContext context) {
    Widget page;
    final theme = Theme.of(context);

    // Show regular pages
    switch (selectedIndex) {
      case 0:
        page = const MyDataPage();
        break;
      case 1:
        page = const MarketPlacePage();
        break;
      case 2:
        page = const HomePage();
        break;
      case 3:
        page = const WalletPage();
        break;
      case 4:
        page = const ProfilePage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Stack(
            children: [
              Container(color: theme.colorScheme.primary, child: page),
              // Fixed notification button at top right
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        // Notification badge
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
            showSelectedLabels: true,
            showUnselectedLabels: true,
            backgroundColor: theme.appBarTheme.backgroundColor,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_rounded),
                label: 'My Data',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shop_two_rounded),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
