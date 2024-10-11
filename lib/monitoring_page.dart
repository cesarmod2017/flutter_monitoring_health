import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_monitoring_health/flutter_monitoring_health.dart';
import 'package:http/http.dart' as http;

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
  String _downloadSpeed = 'Not tested';
  String _uploadSpeed = 'Not tested';
  bool _isTesting = false;
  double _downloadProgress = 0.0;
  //String _currentSpeed = '';
  double _uploadProgress = 0.0;
  String _currentDownloadSpeed = '';
  String _currentUploadSpeed = '';
  // final fileLength = 20000000;
  final fileLength = 5000000; // 20 MB
  static const chunkSize = 256 * 1024; // 256 KB chunks
  bool _isUploading = false;
  final List<double> _speedSamples = [];

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _runSpeedTest() async {
    setState(() {
      _isTesting = true;
      _downloadSpeed = 'Testing...';
      _uploadSpeed = 'Testing...';
      _downloadProgress = 0.0;
      _uploadProgress = 0.0;
      _currentDownloadSpeed = '';
      _currentUploadSpeed = '';
    });

    try {
      final downloadSpeed = await _testDownloadSpeed();
      final uploadSpeed = await _testUploadSpeed();

      setState(() {
        _downloadSpeed = '${downloadSpeed.toStringAsFixed(2)} Mbps';
        _uploadSpeed = '${uploadSpeed.toStringAsFixed(2)} Mbps';
      });
    } catch (e) {
      setState(() {
        _downloadSpeed = 'Error';
        _uploadSpeed = 'Error';
      });
    } finally {
      setState(() {
        _isTesting = false;
        _currentDownloadSpeed = '';
        _currentUploadSpeed = '';
      });
      _loadDeviceInfo();
    }
  }

  Future<double> _testDownloadSpeed() async {
    final testUrl =
        'https://speed.cloudflare.com/__down?bytes=$fileLength'; // 10 MB file
    final stopwatch = Stopwatch()..start();

    final request = http.Request('GET', Uri.parse(testUrl));
    final response = await request.send();

    if (response.statusCode == 200) {
      final totalBytes = fileLength;
      int receivedBytes = 0;
      double lastReportTime = 0;

      final completer = Completer<double>();
      final stream = response.stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (List<int> data, EventSink<List<int>> sink) {
            receivedBytes += data.length;
            final progress = receivedBytes / totalBytes;
            final currentTime = stopwatch.elapsedMilliseconds / 1000;

            if (currentTime - lastReportTime >= 0.1) {
              // Update every 100ms
              final currentSpeed =
                  (receivedBytes * 8 / 1000000) / currentTime; // Mbps
              setState(() {
                _downloadProgress = progress.isFinite
                    ? progress
                    : 0.0; // Ensure progress is not Infinity
                _currentDownloadSpeed =
                    '${currentSpeed.toStringAsFixed(2)} Mbps';
              });
              lastReportTime = currentTime;
            }

            sink.add(data);
          },
        ),
      );

      await stream.drain();
      stopwatch.stop();
      setState(() {
        _downloadProgress = 1;
      });

      final totalTime = stopwatch.elapsedMilliseconds / 1000;
      final speed = (totalBytes * 8 / 1000000) / totalTime; // Mbps
      completer.complete(speed);
      return completer.future;
    } else {
      throw Exception('Failed to test download speed');
    }
  }

  Future<double> _testUploadSpeed() async {
    const testUrl = 'https://speed.cloudflare.com/__up';
    final data = List.generate(fileLength, (index) => Random().nextInt(256));
    final totalBytes = data.length;
    int sentBytes = 0;
    final stopwatch = Stopwatch()..start();

    final request = http.MultipartRequest('POST', Uri.parse(testUrl));

    final streamController = StreamController<List<int>>();
    final stream = http.ByteStream(streamController.stream);

    request.files.add(
      http.MultipartFile(
        'file',
        stream,
        totalBytes,
        filename: 'testfile.bin',
      ),
    );

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _currentUploadSpeed = '0 Mbps';
      _speedSamples.clear();
    });

    Future<void> sendData() async {
      for (int i = 0; i < data.length; i += chunkSize) {
        if (!_isUploading) break;
        final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);
        streamController.add(chunk);
        sentBytes += chunk.length;

        final currentTime = stopwatch.elapsedMilliseconds / 1000;
        final instantSpeed = (chunk.length * 8 / 1000000) /
            (currentTime - stopwatch.elapsedMilliseconds / 1000 + 0.001);
        _speedSamples.add(instantSpeed);

        if (_speedSamples.length > 5) {
          _speedSamples.removeAt(0);
        }

        final avgSpeed =
            _speedSamples.reduce((a, b) => a + b) / _speedSamples.length;

        setState(() {
          _uploadProgress = sentBytes / totalBytes;
          _currentUploadSpeed = '${avgSpeed.toStringAsFixed(2)} Mbps';
        });

        await Future.delayed(const Duration(milliseconds: 100));
      }
      await streamController.close();
    }

    try {
      final sendFuture = sendData();
      final responseFuture = request.send();

      final response = await responseFuture;
      await sendFuture;

      if (response.statusCode == 200) {
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds / 1000;
        final speed = (totalBytes * 8 / 1000000) / totalTime; // Mbps

        setState(() {
          _isUploading = false;
          _uploadProgress = 1;
          _currentUploadSpeed = '${speed.toStringAsFixed(2)} Mbps';
        });

        return speed;
      } else {
        throw Exception('Failed to test upload speed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      throw Exception('Failed to test upload speed: $e');
    }
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
        'Download': _downloadSpeed,
        'Upload': _uploadSpeed,
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
      body: _isLoading && !_isTesting
          ? Center(child: CircularProgressIndicator(color: widget.accentColor))
          : _isTesting
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressIndicator(
                          'Download', _downloadProgress, _currentDownloadSpeed),
                      const SizedBox(height: 30),
                      _buildProgressIndicator(
                          'Upload', _uploadProgress, _currentUploadSpeed),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDeviceInfo,
                  color: widget.accentColor,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isTesting ? null : _runSpeedTest,
        tooltip: 'Test Speed',
        child: _isTesting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.speed),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double progress, String speed) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 15,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              label == 'Download' ? Colors.blue : Colors.green,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Velocidade atual:',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              speed,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
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
