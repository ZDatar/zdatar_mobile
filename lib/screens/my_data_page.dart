import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'location_data_detail_page.dart';
import 'health_data_detail_page.dart';

class MyDataPage extends StatefulWidget {
  const MyDataPage({super.key});

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  final Map<String, bool> _dataStates = {
    'Location': true,
    'Health': true,
    'App Usage': false,
    'Browsing': false,
    'Sensors': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'My Data',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: _dataStates.length,
                  itemBuilder: (context, index) {
                    final category = _dataStates.keys.elementAt(index);
                    final isEnabled = _dataStates[category]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.largeRadius,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (category == 'Location') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LocationDataDetailPage(),
                                ),
                              );
                            } else if (category == 'Health') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HealthDataDetailPage(),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Last Updated: ',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          Text(
                                            '1 day ago',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: Colors.tealAccent,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 8),
                                    Switch(
                                      value: isEnabled,
                                      onChanged: (value) {
                                        setState(() {
                                          _dataStates[category] = value;
                                        });
                                      },
                                      activeColor: isEnabled
                                          ? Colors.green
                                          : Colors.purple,
                                      activeTrackColor: isEnabled
                                          ? Colors.green.withValues(alpha: 0.3)
                                          : Colors.purple.withValues(alpha: 0.3),
                                      inactiveThumbColor: Colors.grey,
                                      inactiveTrackColor: Colors.grey.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
