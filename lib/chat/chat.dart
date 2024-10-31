import "input.dart";
import "message.dart";
import "../config.dart";

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:image_picker/image_picker.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? image;
  bool sendable = true;
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _editCtrl = TextEditingController();

  void _addImage(BuildContext context) async {
    if (image != null) {
      return setState(() {
        image = null;
      });
    }

    final ImageSource? source = await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              title: const Text("Camera"),
              leading: const Icon(Icons.camera),
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
            ),
            ListTile(
              title: const Text("Gallery"),
              leading: const Icon(Icons.photo_library),
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
    if (source == null) return;

    final result = await _picker.pickImage(source: source);
    if (result == null) return;
    final path = result.path;

    final bytes = await File(path).readAsBytes();
    final base64 = base64Encode(bytes);

    setState(() {
      image = "data:image/jpeg;base64,$base64";
    });
  }

  void _sendMessage(BuildContext context) async {
    if (Config.isEmpty) {
      await Config.show(context);
      return;
    }

    final text = _editCtrl.text;
    if (text.isEmpty) return;

    setState(() {
      sendable = false;
    });

    _messages.add(Message(role: MessageRole.user, text: text, image: image));
    final message = Message(role: MessageRole.assistant, text: "");
    final window = _buildContext(_messages);
    _messages.add(message);

    final client = http.Client();

    try {
      final request = http.Request("POST", Uri.parse(Config.apiUrl));
      request.headers["Authorization"] = "Bearer ${Config.apiKey}";
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode(window);

      final response = await client.send(request);
      final stream = response.stream.transform(utf8.decoder);

      if (response.statusCode != 200) {
        throw Exception("bad request");
      }

      outer:
      await for (final chunk in stream) {
        final lines = LineSplitter.split(chunk).toList();

        for (final line in lines) {
          if (!line.startsWith("data:")) continue;
          final raw = line.substring(5);

          if (raw.trim() == "[DONE]") break outer;
          final json = jsonDecode(raw);

          setState(() {
            message.text += json["choices"][0]["delta"]["content"];
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          });
        }
      }

      _editCtrl.clear();
    } catch (e) {
      _editCtrl.text = text;
      _messages.length -= 2;
    } finally {
      client.close();
    }

    setState(() {
      image = null;
      sendable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            itemCount: _messages.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final message = _messages[index];
              return MessageWidget(message: message);
            },
          ),
        ),
        InputWidget(
          editable: sendable,
          controller: _editCtrl,
          files: image != null ? 1 : 0,
          addImage: sendable ? _addImage : null,
          sendMessage: sendable ? _sendMessage : null,
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                image = null;
                _messages.length = 0;
              });
            },
            icon: const Icon(Icons.delete),
          ),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () async {
                  await Config.show(context);
                },
                icon: const Icon(Icons.settings),
              );
            },
          )
        ],
        title: const Text("ChatBot"),
      ),
      body: Container(child: child),
    );
  }
}

Map<String, Object> _buildContext(List<Message> messages) {
  Map<String, Object> context = {
    "model": Config.model,
    "stream": true,
  };
  List<Map<String, Object>> list = [];

  if (Config.system.isNotEmpty) {
    list.add({"role": "system", "content": Config.system});
  }

  for (final pair in messages.indexed) {
    final Object content;
    final index = pair.$1;
    final message = pair.$2;
    final image = message.image;

    if (index != messages.length - 1 || image == null) {
      content = message.text;
    } else {
      content = [
        {
          "type": "image_url",
          "image_url": {"url": image},
        },
        {
          "type": "text",
          "text": message.text,
        },
      ];
    }

    list.add({"role": message.role.name, "content": content});
  }

  context["messages"] = list;
  return context;
}
