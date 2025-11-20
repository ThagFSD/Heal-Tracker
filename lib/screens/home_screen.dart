// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ble_controller.dart'; 
import '../controllers/theme_controller.dart';
import '../controllers/auth_controller.dart'; // <-- IMPORT MỚI
import 'tabs/dashboard_tab.dart';
import 'tabs/charts_tab.dart';
import 'tabs/reports_tab.dart';
import 'settings_screen.dart'; 
import 'tabs/workout_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    DashboardTab(),
    ChartsTab(),
    ReportsTab(),
    const WorkoutTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr),
        elevation: 1,
        actions: [
          IconButton(
            tooltip: "Ngắt kết nối thiết bị",
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
              Get.find<BLEController>().disconnectDevice();
            },
          )
        ],
      ),
      drawer: Drawer(
        child: Builder(
          builder: (drawerContext) { 
            final ThemeController themeController = Get.find();
            final AuthController authController = Get.find(); // <-- LẤY AUTH

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor, 
                  ),
                  child: Text(
                    'app_title'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('settings_info'.tr), 
                  onTap: () {
                    Navigator.of(drawerContext).pop(); 
                    Get.to(() => const SettingsScreen()); 
                  },
                ),
                Obx(() => ListTile(
                      leading: Icon(
                        themeController.isDarkMode.value ? Icons.brightness_3 : Icons.brightness_7,
                      ),
                      title: Text(
                        themeController.isDarkMode.value ? 'switch_theme_light'.tr : 'switch_theme_dark'.tr,
                      ),
                      onTap: () {
                        themeController.switchTheme();
                        Navigator.of(drawerContext).pop();
                      },
                    )),
                const Divider(),
                // ===========================================
                // THAY ĐỔI MỚI: Thêm nút Đăng xuất
                // ===========================================
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(drawerContext).pop();
                    authController.signOut();
                  },
                ),
              ],
            );
          }
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'tab_dashboard'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: 'tab_charts'.tr,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article),
            label: 'tab_reports'.tr,
          ),
          BottomNavigationBarItem( // <-- ITEM MỚI
            icon: const Icon(Icons.directions_run),
            label: 'Workout',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}