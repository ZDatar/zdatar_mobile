import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/home_page.dart';
import 'screens/favorites_page.dart';
import 'screens/my_data_page.dart';
import 'screens/market_place_page.dart';
import 'screens/deal_detail_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF01005E)),
        ),
        home: MyHomePage(),
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
  bool showDetailPage = false;
  Map<String, dynamic>? currentDeal;

  void showDealDetail(String dealTitle, String reward, IconData icon) {
    setState(() {
      showDetailPage = true;
      currentDeal = {
        'title': dealTitle,
        'reward': reward,
        'icon': icon,
      };
    });
  }

  void hideDealDetail() {
    setState(() {
      showDetailPage = false;
      currentDeal = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    
    if (showDetailPage && currentDeal != null) {
      // Show deal detail page
      page = DealDetailPage(
        dealTitle: currentDeal!['title'],
        reward: currentDeal!['reward'],
        icon: currentDeal!['icon'],
        onBack: hideDealDetail,
      );
    } else {
      // Show regular pages
      switch (selectedIndex) {
        case 0:
          page = MyDataPage();
          break;
        case 1:
          page = MarketPlacePage(onDealTap: showDealDetail);
          break;
        case 2:
          page = HomePage();
          break;
        case 3:
          page = FavoritesPage(); // Placeholder for Wallet
          break;
        case 4:
          page = FavoritesPage(); // Placeholder for Profile
          break;
        default:
          throw UnimplementedError('no widget for $selectedIndex');
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: page,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
                showDetailPage = false; // Hide detail page when switching tabs
                currentDeal = null;
              });
            },
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
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
