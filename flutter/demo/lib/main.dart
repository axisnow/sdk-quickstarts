import 'package:flutter/material.dart';
import 'package:axsecurity_flutter_plugin/axsecurity_flutter_plugin.dart';
import 'package:dio/dio.dart';
import 'package:axsecurity_flutter_plugin/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
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
  final StringBuffer _sb = StringBuffer();
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
              _buildButton(title: '初始化', onTap: _init),
              _buildButton(title: '请求', onTap: _request),
              _buildButton(title: 'HttpClient', onTap: _onUsedHttpClient),
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

  ///初始化
  _init() async {
    // *** COMMENT THE LINE BELOW FOR AgentSDK***//
    var accessKeyID = 'your accessKeyID from SDK Deployment';
    var accessKeySecret = 'your accessKeySecret from SDK Deployment';
    var edgeAddresses = ['edge IP'];

    Config cfg = Config(
        accessKeyID: accessKeyID,
        accessKeySecret: accessKeySecret,
        edgeAddresses: edgeAddresses,
        dns: DnsConfig(edgeDohResolveDomains: ["*.example.com"]),
        secureProxyEnabled: true);

    var result = await AxService.initialize(config: cfg);
    _log(result == 0 ? "axis init success" : "axis init failure!");
  }

  ///请求
  _request() async {
    ///获取本地代理IP
    var config =
        await AxService.getLocalTCPProxy(host: "example.com", port: 80);
    if (config == null) {
      _log("getLocalTCPProxy failure!");
      return;
    }

    _log("getLocalTCPProxy1");

    var dio = Dio();
    var response = await dio.get("http://${config.ip}:${config.port}",
        options: Options(headers: {
          //set sni
          'Host': 'example.com'
        }));
    _log("http response through axis proxy:${response.data}");
  }

  _onUsedHttpClient() async {
    _log("$tag: Checking connectivity...");
    try {
      http.Client client = AxClient();
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

  void _log(String text) {
    _sb
      ..clear()
      ..writeln(text);
    setState(() {});
  }
}

class AxisDioInterceptor extends Interceptor {
  // Using dynamic to avoid the private type warning while still accessing the methods
  late dynamic _state;
  AxisDioInterceptor(dynamic state) {
    _state = state;
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    var uri = options.uri;

    ///获取本地代理IP
    ///

    _state._log("uri =$uri");

    var config =
        await AxService.getLocalTCPProxy(host: uri.host, port: uri.port);
    if (config == null) {
      _state._log("config null");

      handler.reject(DioError(
          requestOptions: options, error: "getLocalTCPProxy failure!"));
      return;
    }
    _state._log("config.ip =${config.ip}");

    var path = uri.replace(host: config.ip, port: config.port).toString();
    var headers = options.headers;
    headers["Host"] = uri.host;

    _state._log("path =$path");

    handler.next(options.copyWith(path: path, headers: headers));
  }
}
