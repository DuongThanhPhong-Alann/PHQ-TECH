import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ThreeDViewerPage extends StatefulWidget {
  const ThreeDViewerPage({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<ThreeDViewerPage> createState() => _ThreeDViewerPageState();
}

class _ThreeDViewerPageState extends State<ThreeDViewerPage> {
  late final WebViewController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) =>
              setState(() => _progress = progress.clamp(0, 100) / 100),
          onNavigationRequest: (request) =>
              NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 1)
            LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }
}
