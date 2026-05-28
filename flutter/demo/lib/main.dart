import 'package:flutter/material.dart';
// *** UNCOMMENT THE LINES BELOW FOR SDK ***
// import 'package:flutter/services.dart';
// import 'package:axsecurity_flutter_plugin/axsecurity_flutter_plugin.dart';
// import 'package:axsecurity_flutter_plugin/config.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'dart:async';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // *** UNCOMMENT THE LINES BELOW FOR SDK ***
  // int? result;
  // try {
  //   AxConfig cfg = AxConfig(
  //       accessKeyId: 'your accessKeyId from SDK Deployment',
  //       accessKeySecret: 'your accessKeySecret from SDK Deployment',
  //       edgeNodes: ['edge IP'],
  //       dns: AxDnsConfig(edgeDohResolveDomains: ["*.example.com"]));
  //   result = await AxService.initialize(config: cfg);
  // } on PlatformException {
  //   result = -1;
  // }
  // if (result != 0) {
  //   debugPrint('SDK initialization failed: $result');
  // }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
// logging tag
  static const String tag = "HTTPClIENT FLUTTER";
  static const String demoURL = "https://example.com";
  static const String wsURL = "wss://echo.websocket.org";
  final StringBuffer _sb = StringBuffer();
  bool _wsBusy = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        backgroundColor: Colors.white,
        body: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildButton(title: 'HTTP Request', onTap: _onUsedHttpClient),
              _buildButton(title: 'WebSocket', onTap: _onUsedWebSocket),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 320,
                    child: Text(
                      _sb.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  ///构建按钮
  Widget _buildButton({required VoidCallback onTap, required String title}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 320,
        height: 50,
        decoration: BoxDecoration(
            color: const Color(0xfff1f1f1),
            border: Border.all(color: Colors.grey, width: 1)),
        alignment: Alignment.center,
        child: Text(title),
      ),
    );
  }

  _onUsedHttpClient() async {
    _log("$tag: Checking connectivity...");
    try {
      // *** COMMENT THE LINE BELOW FOR SDK ***
      http.Client client = http.Client();

      // *** UNCOMMENT THE LINE BELOW FOR SDK ***
      // http.Client client = AxClient();

      http.Response response = await client.get(Uri.parse(demoURL));
      if (response.statusCode == 200) {
        _log(
            "$tag: Received connectivity response: ${utf8.decode(response.bodyBytes)}");
      } else {
        _log("$tag: Error on connectivity request: ${response.statusCode}");
      }
    } catch (e) {
      _log("$tag: ${e.toString()}");
    }
    setState(() {});
  }

  _onUsedWebSocket() async {
    if (_wsBusy) return;
    _wsBusy = true;
    _sb.clear();
    _append("$tag: Connecting to $wsURL ...");
    IOWebSocketChannel? channel;
    StreamSubscription<dynamic>? sub;
    var aborted = false;
    try {
      // *** COMMENT THE LINE BELOW FOR SDK ***
      channel = IOWebSocketChannel.connect(Uri.parse(wsURL));

      // *** UNCOMMENT THE LINES BELOW FOR SDK ***
      // AxHttpClient exposes the SDK local proxy via findProxy, so the WebSocket
      // upgrade request is routed through the Axis proxy transparently.
      // channel = IOWebSocketChannel.connect(
      //   Uri.parse(wsURL),
      //   customClient: AxHttpClient(),
      // );

      await channel.ready;
      _append("$tag: WebSocket connected");

      sub = channel.stream.listen(
        (data) => _append("$tag: echo <- $data"),
        onDone: () {
          _append("$tag: WebSocket closed");
          aborted = true;
        },
        onError: (Object e) {
          _append("$tag: WebSocket error: $e");
          aborted = true;
        },
        cancelOnError: true,
      );

      const totalRounds = 5;
      const interval = Duration(seconds: 2);
      for (var i = 1; i <= totalRounds; i++) {
        if (aborted) break;
        final payload = "hello $i from axsecurity flutter demo";
        channel.sink.add(payload);
        _append("$tag: sent ($i/$totalRounds) -> $payload");
        if (i < totalRounds) await Future.delayed(interval);
      }
    } catch (e) {
      _append("$tag: ${e.toString()}");
    } finally {
      await sub?.cancel();
      await channel?.sink.close(ws_status.normalClosure);
      _wsBusy = false;
    }
  }

  void _log(String text) {
    _sb
      ..clear()
      ..writeln(text);
    setState(() {});
  }

  void _append(String text) {
    _sb.writeln(text);
    setState(() {});
  }
}
