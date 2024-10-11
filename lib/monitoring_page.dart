import 'package:flutter/material.dart';
import 'package:flutter_monitoring_health/flutter_monitoring_health.dart';

class MonitoringPage extends StatefulWidget {
  final Color? appBarColor;
  final Color? backgroundColor;
  final Color? accentColor;
  final Color? textColor;

  const MonitoringPage({
    super.key,
    this.appBarColor,
    this.backgroundColor,
    this.accentColor,
    this.textColor,
  });

  @override
  MonitoringPageState createState() => MonitoringPageState();
}

class MonitoringPageState extends State<MonitoringPage> {
  Map<String, String> _deviceInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
    });

    final deviceModel = await FlutterMonitoringHealth.getDeviceModel();
    final osVersion = await FlutterMonitoringHealth.getOSVersion();
    final totalMemory = await FlutterMonitoringHealth.getTotalMemory();
    final usedMemory = await FlutterMonitoringHealth.getUsedMemory();
    final appMemoryUsage = await FlutterMonitoringHealth.getAppMemoryUsage();
    final totalDiskSpace = await FlutterMonitoringHealth.getTotalDiskSpace();
    final usedDiskSpace = await FlutterMonitoringHealth.getUsedDiskSpace();
    final availableDiskSpace =
        await FlutterMonitoringHealth.getAvailableDiskSpace();

    setState(() {
      _deviceInfo = {
        'Modelo': deviceModel ?? 'Não suportado',
        'Sistema': osVersion ?? 'Não suportado',
        'Memória Total': totalMemory,
        'Memória Usada': usedMemory,
        'Memória do App': appMemoryUsage,
        'Armazenamento Total': totalDiskSpace,
        'Armazenamento Usado': usedDiskSpace,
        'Armazenamento Livre': availableDiskSpace,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.grey[100],
      appBar: AppBar(
        title: const Text('Monitoramento de Saúde'),
        backgroundColor: widget.appBarColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.accentColor))
          : RefreshIndicator(
              onRefresh: _loadDeviceInfo,
              color: widget.accentColor,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _deviceInfo.length,
                itemBuilder: (context, index) {
                  final entry = _deviceInfo.entries.elementAt(index);
                  return _buildInfoTile(entry.key, entry.value);
                },
              ),
            ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    IconData icon;
    switch (title) {
      case 'Modelo':
        icon = Icons.phone_android;
        break;
      case 'Sistema':
        icon = Icons.system_update;
        break;
      case 'Memória Total':
      case 'Memória Usada':
      case 'Memória do App':
        icon = Icons.memory;
        break;
      case 'Armazenamento Total':
      case 'Armazenamento Usado':
      case 'Armazenamento Livre':
        icon = Icons.storage;
        break;
      default:
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.accentColor ?? Colors.blue, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor ?? Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: widget.textColor?.withOpacity(0.8) ?? Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
