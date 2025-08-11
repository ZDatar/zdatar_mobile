import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zdatar_mobile/screens/wallet_page.dart';
import 'models/app_state.dart';
import 'screens/home_page.dart';
import 'screens/favorites_page.dart';
import 'screens/my_data_page.dart';
import 'screens/market_place_page.dart';
import 'theme/app_theme.dart';
import 'screens/profile_page.dart';

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
                      _showNotificationDialog(context);
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

  void _showNotificationDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            children: [
              Icon(
                Icons.notifications,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Notifications',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNotificationItem(
                  context,
                  'New reward earned!',
                  'You earned 5.00 ZDT from data sharing',
                  '2 min ago',
                  Icons.monetization_on,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildNotificationItem(
                  context,
                  'Market update',
                  'ZDT price increased by 12%',
                  '1 hour ago',
                  Icons.trending_up,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildNotificationItem(
                  context,
                  'Security alert',
                  'New login detected from iPhone',
                  '3 hours ago',
                  Icons.security,
                  Colors.orange,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Mark all as read',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String message,
    String time,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
