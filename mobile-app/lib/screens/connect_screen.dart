import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/robot_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RobotService _robotService = RobotService();

  List<ScanResult> bluetoothDevices = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  bool isConnecting = false;
  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;

  List<String> wifiNetworks = [];
  String? connectedWifi;
  bool isWifiScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to connection status changes
    _robotService.connectionStatus.listen((status) {
      setState(() {
        connectionStatus = status;
        isConnecting = status == ConnectionStatus.connecting;

        if (status == ConnectionStatus.connected &&
            _robotService.connectionType == ConnectionType.bluetooth) {
          connectedDevice = _robotService.connectedBluetoothDevice;
        } else if (status == ConnectionStatus.disconnected) {
          connectedDevice = null;
        }
      });
    });

    // Check initial connection status
    connectionStatus = _robotService.status;
    if (connectionStatus == ConnectionStatus.connected &&
        _robotService.connectionType == ConnectionType.bluetooth) {
      connectedDevice = _robotService.connectedBluetoothDevice;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void startBluetoothScan() async {
    setState(() {
      isScanning = true;
      bluetoothDevices.clear();
    });

    try {
      // Request permissions first
      bool permissionsGranted = await _robotService.requestPermissions();
      if (!permissionsGranted) {
        throw Exception(
            'Bluetooth permissions not granted. Please enable them in settings.');
      }

      // Scan for devices
      _robotService.scanForDevices().listen((scanResults) {
        setState(() {
          bluetoothDevices = scanResults;
        });
      }, onError: (error) {
        setState(() {
          isScanning = false;
        });
        _showErrorSnackBar('Scanning failed: $error');
      });

      // Stop scanning after 10 seconds
      Future.delayed(Duration(seconds: 10), () {
        setState(() {
          isScanning = false;
        });
        FlutterBluePlus.stopScan();
      });
    } catch (e) {
      setState(() {
        isScanning = false;
      });
      _showErrorSnackBar('Error starting scan: $e');
    }
  }

  void connectToBluetoothDevice(BluetoothDevice device) async {
    try {
      bool success = await _robotService.connectBluetooth(device);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Connected to ${device.name ?? 'Unknown Device'}')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar('Failed to connect to ${device.name ?? 'device'}');
      }
    } catch (e) {
      _showErrorSnackBar('Connection error: $e');
    }
  }

  void disconnectDevice() async {
    try {
      await _robotService.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('Disconnected from robot'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Disconnect error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void loadWifiNetworks() async {
    setState(() {
      isWifiScanning = true;
    });

    try {
      // Get available networks from robot service
      List<String> networks = await _robotService.getAvailableWifiNetworks();
      setState(() {
        wifiNetworks = networks;
        isWifiScanning = false;
      });
    } catch (e) {
      setState(() {
        isWifiScanning = false;
      });
      _showErrorSnackBar('WiFi scan failed: $e');
    }
  }

  void connectToWifi(String ssid) async {
    try {
      // Show password dialog for WiFi connection
      String? password = await _showPasswordDialog(ssid);
      if (password == null) return; // User cancelled

      bool success = await _robotService.connectWifi(ssid);

      if (success) {
        setState(() {
          connectedWifi = ssid;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Connected to $ssid'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorSnackBar('Failed to connect to $ssid');
      }
    } catch (e) {
      _showErrorSnackBar('WiFi connection error: $e');
    }
  }

  Future<String?> _showPasswordDialog(String ssid) async {
    TextEditingController passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connect to $ssid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter WiFi password:'),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
              child: Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Icon(Icons.bluetooth),
                text: 'Bluetooth',
              ),
              Tab(
                icon: Icon(Icons.wifi),
                text: 'WiFi',
              ),
            ],
            labelStyle: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.comicNeue(),
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBluetoothTab(),
              _buildWifiTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBluetoothTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Card
          Card(
            color: _getStatusColor(connectionStatus).withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(connectionStatus),
                    color: _getStatusColor(connectionStatus),
                    size: 32,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Status',
                          style: GoogleFonts.comicNeue(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getStatusText(connectionStatus),
                          style: GoogleFonts.comicNeue(
                            fontSize: 16,
                            color: _getStatusColor(connectionStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (connectedDevice != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Connected to: ${connectedDevice!.name ?? 'Unknown Device'}',
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (connectionStatus == ConnectionStatus.connected)
                    ElevatedButton(
                      onPressed: disconnectDevice,
                      child: Text('Disconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Scan Control Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Devices',
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: isScanning || isConnecting
                          ? null
                          : startBluetoothScan,
                      icon: Icon(isScanning ? Icons.stop : Icons.search),
                      label:
                          Text(isScanning ? 'Scanning...' : 'Scan for Robots'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          if (isScanning)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Scanning for robots...',
                    style: GoogleFonts.comicNeue(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Device List
          ...bluetoothDevices
              .map((scanResult) => _buildBluetoothDeviceCard(scanResult)),
        ],
      ),
    );
  }

  Widget _buildBluetoothDeviceCard(ScanResult scanResult) {
    BluetoothDevice device = scanResult.device;
    bool isConnectedToThis = connectedDevice?.id == device.id;
    bool showDevice = device.name.isNotEmpty &&
        (device.name.toLowerCase().contains('robot') ||
            device.name.toLowerCase().contains('esp32') ||
            device.name.toLowerCase().contains('arduino') ||
            device.name.toLowerCase().contains('bot'));

    // Always show devices that match robot-like names, or if no filter matches show all
    if (!showDevice && bluetoothDevices.length < 5) showDevice = true;

    if (!showDevice) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isConnectedToThis
                ? Colors.green.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bluetooth,
            color: isConnectedToThis ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.id.id),
            if (scanResult.rssi != 0)
              Text('Signal: ${scanResult.rssi} dBm',
                  style: TextStyle(fontSize: 12)),
          ],
        ),
        trailing: isConnectedToThis
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connected',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            : ElevatedButton(
                onPressed: isConnecting
                    ? null
                    : () => connectToBluetoothDevice(device),
                child: Text(isConnecting ? 'Connecting...' : 'Connect'),
              ),
      ),
    );
  }

  Widget _buildWifiTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'WiFi Connection',
                          style: GoogleFonts.comicNeue(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'WiFi connection is currently in development. Use Bluetooth for the best experience.',
                    style: GoogleFonts.comicNeue(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WiFi Networks',
                    style: GoogleFonts.comicNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: isWifiScanning ? null : loadWifiNetworks,
                      icon: Icon(isWifiScanning
                          ? Icons.hourglass_empty
                          : Icons.refresh),
                      label: Text(
                          isWifiScanning ? 'Scanning...' : 'Scan for Networks'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          if (isWifiScanning) Center(child: CircularProgressIndicator()),
          ...wifiNetworks.map((ssid) => _buildWifiNetworkCard(ssid)),
        ],
      ),
    );
  }

  Widget _buildWifiNetworkCard(String ssid) {
    bool isConnectedToThis = connectedWifi == ssid;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isConnectedToThis
                ? Colors.green.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.wifi,
            color: isConnectedToThis ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          ssid,
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
        ),
        trailing: isConnectedToThis
            ? ElevatedButton(
                onPressed: null,
                child: Text('Connected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              )
            : ElevatedButton(
                onPressed: () => connectToWifi(ssid),
                child: Text('Connect'),
              ),
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.blue;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.check_circle;
      case ConnectionStatus.connecting:
        return Icons.sync;
      case ConnectionStatus.disconnected:
        return Icons.bluetooth_disabled;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected to Robot';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Not Connected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }
}
