import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/robot_service.dart';
import 'screens/home_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/code_screen.dart';
import 'screens/run_screen.dart';
import 'screens/sensors_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        // Robot service is singleton, so we provide it here for easy access
        Provider<RobotService>(create: (_) => RobotService()),
      ],
      child: const RoboCodeApp(),
    ),
  );
}

class RoboCodeApp extends StatelessWidget {
  const RoboCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoboCode',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.blue[50],
        textTheme: GoogleFonts.comicNeueTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.indigo[900],
          displayColor: Colors.indigo[900],
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: GoogleFonts.comicNeue(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const RoboCodeHomePage(),
    );
  }
}

class RoboCodeHomePage extends StatefulWidget {
  const RoboCodeHomePage({super.key});

  @override
  RoboCodeHomePageState createState() => RoboCodeHomePageState();
}

class RoboCodeHomePageState extends State<RoboCodeHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  RobotService? _robotService;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    // Initialize robot service and listen to connection changes
    _initializeRobotService();
  }

  void _initializeRobotService() {
    _robotService = Provider.of<RobotService>(context, listen: false);

    // Listen to connection status changes
    _robotService!.connectionStatus.listen((status) {
      setState(() {
        _isConnected = status == ConnectionStatus.connected;
      });

      // Update app state with connection info
      final appState = Provider.of<AppState>(context, listen: false);
      String robotName = '';
      if (_isConnected && _robotService!.connectedBluetoothDevice != null) {
        robotName =
            _robotService!.connectedBluetoothDevice!.name ?? 'Unknown Robot';
      }
      appState.updateConnectionStatus(_isConnected, robotName: robotName);
    });

    // Check initial connection status
    _isConnected = _robotService!.isConnected;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static final List<Widget> _widgetOptions = [
    const HomeScreen(),
    const ConnectScreen(),
    const CodeScreen(),
    Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Use the Code Screen to build and run your program',
              style: GoogleFonts.comicNeue(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
    const SensorsScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 32),
            const SizedBox(width: 8),
            Text(
              'RoboCode',
              style: GoogleFonts.comicNeue(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Connection status indicator
          Container(
            margin: EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: _isConnected ? Colors.green : Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  _isConnected ? 'Connected' : 'Offline',
                  style: GoogleFonts.comicNeue(
                    fontSize: 12,
                    color: _isConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: Consumer<AppState>(
            builder: (context, appState, child) => LinearProgressIndicator(
              value: appState.completedLevels.length / 5.0,
              backgroundColor: Colors.indigo[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 32),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.bluetooth_rounded, size: 32),
                  if (_isConnected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Connect',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.extension_rounded, size: 32),
              label: 'Code',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_rounded, size: 32),
              label: 'Run',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.dashboard_rounded, size: 32),
                  if (_isConnected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Sensors',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.indigo[200],
          selectedLabelStyle: GoogleFonts.comicNeue(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.comicNeue(
            fontSize: 14,
          ),
          onTap: onItemTapped,
        ),
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Need Help?',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHelpItem(
                            'Connect to your robot in the Connect tab'),
                        _buildHelpItem('Drag blocks from the left toolbox'),
                        _buildHelpItem('Connect blocks to create sequences'),
                        _buildHelpItem('Click Run to test on your robot'),
                        _buildHelpItem('Save your program when it works!'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Got it!',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      if (!_isConnected)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onItemTapped(1); // Go to Connect tab
                          },
                          child: const Text('Connect Robot'),
                        ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
              label: Text(
                'Help',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              icon: const Icon(Icons.help_outline_rounded),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.comicNeue(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
