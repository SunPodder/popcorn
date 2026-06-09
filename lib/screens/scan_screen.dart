import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/user_service.dart';
import 'home_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final UserService _userService = UserService();
  bool _isScanning = false;
  double _progress = 0.0;
  List<String> _workingServers = [];
  int _totalServers = 0;
  int _scannedCount = 0;

  final List<String> _serversToScan = [
    'http://samftp.com',
    'http://ftpbd.net',
    'http://circleftp.net',
    'http://main.circleftp.net',
    'http://moviemazic.xyz',
    'http://discoveryftp.net',
    'http://elaach.com',
    'http://nagordola.com.bd',
    'http://dhakamovie.com',
    'http://showtimebd.com',
    'http://naturalbd.com',
    'http://amberit.com.bd',
    'http://dotinternet.net.bd',
    'http://link3.net',
    'http://khulnaflix.net',
    'http://media.ctgfun.com',
    'http://jagobd.com',
    'http://bongobd.com',
    'http://10.1.1.1',
  ];

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _workingServers = [];
      _scannedCount = 0;
      _totalServers = _serversToScan.length;
    });

    for (String url in _serversToScan) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 2),
        );
        if (response.statusCode == 200) {
          _workingServers.add(url);
        }
      } catch (e) {
        // Server not reachable or timeout
      }

      if (mounted) {
        setState(() {
          _scannedCount++;
          _progress = _scannedCount / _totalServers;
        });
      }
    }

    await _userService.setWorkingServers(_workingServers);
    await _userService.setHasScanned(true);

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.radar_outlined,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Discover Local Servers',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ll scan for BDIX FTP and movie servers available on your connection.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isScanning) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scanning... ${(_progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else if (_scannedCount > 0) ...[
                Text(
                  'Scan Complete!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Found ${_workingServers.length} working servers',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isScanning
                      ? null
                      : (_scannedCount > 0 ? _continueToHome : _startScan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isScanning
                        ? 'Scanning...'
                        : (_scannedCount > 0 ? 'Continue' : 'Start Scan'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }
}
