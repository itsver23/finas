import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentPage extends StatefulWidget {
  final String url;
  const PaymentPage({super.key, required this.url});
  @override State<PaymentPage> createState() => _PaymentState();
}
class _PaymentState extends State<PaymentPage> {
  WebViewController? controller;
  bool opening = false;
  @override void initState() {
    super.initState();
    if (!kIsWeb) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.url));
    }
  }
  Future<void> openInBrowser() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid secure payment URL.')));
      return;
    }
    setState(() => opening = true);
    try {
      final ok = await launchUrl(uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank');
      if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment page.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment page error: $e')));
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Secure Xendit Checkout'), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
    ]),
    body: Column(children: [
      const Padding(padding: EdgeInsets.all(8), child: Text('Check My Orders after payment. Only the verified server webhook confirms PAID status.', textAlign: TextAlign.center)),
      Expanded(child: kIsWeb
        ? Center(child: ElevatedButton(
            onPressed: opening ? null : openInBrowser,
            child: const Text('Continue to Xendit'),
          ))
        : WebViewWidget(controller: controller!)),
    ]),
  );
}
