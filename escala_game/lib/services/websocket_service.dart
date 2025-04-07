import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  String get url {
    if (kIsWeb) {
      return 'ws://localhost:5000/ws'; // Flutter Web (navegador)
    } else if (Platform.environment.containsKey('ANDROID_EMULATOR')) {
      return 'ws://10.0.2.2:5000/ws'; // Emulador Android
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'ws://10.0.2.2:5000/ws'; // Dispositivos móviles
    } else {
      return 'ws://localhost:5000/ws'; // Otros entornos locales
    }
  }

  WebSocketChannel? channel;
  Function(Map<String, dynamic>)? onMessage;

  void connect(Function(Map<String, dynamic>) onMessageCallback) {
    channel = WebSocketChannel.connect(Uri.parse(url));
    onMessage = onMessageCallback;

    channel!.stream.listen(
          (message) {
        final data = jsonDecode(message);
        onMessage!(data);
      },
      onError: (error) {
        print('WebSocket Error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  void sendMessage(Map<String, dynamic> message) {
    if (channel != null) {
      channel!.sink.add(jsonEncode(message));
    }
  }

  void disconnect() {
    channel?.sink.close();
    channel = null;
  }
}