import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/home_page.dart';
import 'screens/favorites_page.dart';
import 'screens/my_data_page.dart';
import 'screens/market_place_page.dart';
import 'theme/app_theme.dart';

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
        page = const FavoritesPage(); // Placeholder for Wallet
        break;
      case 4:
        page = const FavoritesPage(); // Placeholder for Profile
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Container(color: theme.colorScheme.primary, child: page),
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
                icon: Icon(Icons.dataset),
                label: 'My Data',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shop_2_rounded),
                label: 'Market',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wallet),
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
