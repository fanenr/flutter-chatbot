// This file is part of ChatBot.
//
// ChatBot is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChatBot is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ChatBot. If not, see <https://www.gnu.org/licenses/>.

import "chat.dart";
import "message.dart";
import "current.dart";
import "../util.dart";
import "../gen/l10n.dart";

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:langchain/langchain.dart";
import "package:image_picker/image_picker.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";

class InputWidget extends ConsumerStatefulWidget {
  final ScrollController scrollCtrl;

  const InputWidget({
    super.key,
    required this.scrollCtrl,
  });

  @override
  ConsumerState<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends ConsumerState<InputWidget> {
  static int sendTimes = 0;
  static final ImagePicker imagePicker = ImagePicker();
  final TextEditingController inputCtrl = TextEditingController();

  Future<void> _addImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          alignment: WrapAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: Text(S.of(context).camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(S.of(context).gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        );
      },
    );
    if (source == null) return;

    final result = await imagePicker.pickImage(source: source);
    if (result == null) return;

    final compressed = await FlutterImageCompress.compressWithFile(result.path,
        quality: 60, minWidth: 1024, minHeight: 1024);
    Uint8List bytes = compressed ?? await File(result.path).readAsBytes();

    if (compressed == null && context.mounted) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).image_compress_failed),
      );
    }

    final base64 = base64Encode(bytes);
    setState(() => CurrentChat.image = base64);
  }

  void _clearImage(BuildContext context) {
    setState(() => CurrentChat.image = null);
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = inputCtrl.text;
    if (text.isEmpty) return;

    final messages = CurrentChat.messages;
    final apiUrl = CurrentChat.apiUrl;
    final apiKey = CurrentChat.apiKey;
    final model = CurrentChat.model;

    if (apiUrl == null || apiKey == null || model == null) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_bot_api_first),
      );
      return;
    }

    messages.add(Message(
      text: text,
      role: MessageRole.user,
      image: CurrentChat.image,
    ));

    final times = ++sendTimes;
    final scrollCtrl = widget.scrollCtrl;
    final chatContext = _buildContext(messages);
    final assistant = Message(text: "", role: MessageRole.assistant);

    messages.add(assistant);
    ref.read(messagesProvider.notifier).notify();
    scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);

    setState(() {
      inputCtrl.clear();
      CurrentChat.image = null;
      CurrentChat.status = CurrentChatStatus.responding;
    });

    try {
      final llm = ChatOpenAI(
        apiKey: apiKey,
        baseUrl: apiUrl,
        defaultOptions: ChatOpenAIOptions(
          model: model,
          maxTokens: CurrentChat.maxTokens,
          temperature: CurrentChat.temperature,
        ),
      );

      if (CurrentChat.stream ?? true) {
        final stream = llm.stream(PromptValue.chat(chatContext));
        await for (final chunk in stream) {
          if (!CurrentChat.isResponding || times != sendTimes) return;
          assistant.text += chunk.output.content;
          ref.read(messageProvider(assistant).notifier).notify();
          scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
        }
      } else {
        final result = await llm.invoke(PromptValue.chat(chatContext));
        if (!CurrentChat.isResponding || times != sendTimes) return;
        assistant.text += result.output.content;
        ref.read(messageProvider(assistant).notifier).notify();
        scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
      }
    } catch (e) {
      if (!CurrentChat.isResponding || times != sendTimes) return;
      if (context.mounted) {
        Util.showSnackBar(
          context: context,
          content: Text("$e"),
          duration: const Duration(milliseconds: 1500),
        );
      }
      if (assistant.text.isEmpty) {
        messages.length -= 2;
        inputCtrl.text = text;
        ref.read(messagesProvider.notifier).notify();
      }
    }

    if (await CurrentChat.save()) {
      ref.read(chatsProvider.notifier).notify();
    }
    setState(() => CurrentChat.status = CurrentChatStatus.nothing);
    ref.read(messageProvider(assistant).notifier).notify();
  }

  Future<void> _stopResponding(BuildContext context) async {
    setState(() => CurrentChat.status = CurrentChatStatus.nothing);
    final list = CurrentChat.messages;

    final user = list[list.length - 2];
    final assistant = list.last;

    if (assistant.text.isEmpty) {
      list.removeRange(list.length - 2, list.length);
      ref.read(messagesProvider.notifier).notify();
      inputCtrl.text = user.text;
    } else if (await CurrentChat.save()) {
      ref.read(chatsProvider.notifier).notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = CurrentChat.image != null;
    final isResponding = CurrentChat.isResponding;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, left: 6, right: 6, bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Badge(
              isLabelVisible: hasImage,
              label: const Text("1"),
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () async {
                  if (hasImage) {
                    _clearImage(context);
                  } else {
                    await _addImage(context);
                  }
                },
                icon: Icon(hasImage ? Icons.delete : Icons.add_photo_alternate),
              ),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  maxLines: null,
                  autofocus: false,
                  controller: inputCtrl,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: S.of(context).enter_your_message,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                if (isResponding) {
                  await _stopResponding(context);
                } else {
                  await _sendMessage(context);
                }
              },
              icon: Icon(isResponding ? Icons.stop_circle : Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

List<ChatMessage> _buildContext(List<Message> list) {
  final context = <ChatMessage>[];

  if (CurrentChat.systemPrompts != null) {
    context.add(ChatMessage.system(CurrentChat.systemPrompts!));
  }

  for (final item in list) {
    switch (item.role) {
      case MessageRole.assistant:
        context.add(ChatMessage.ai(item.text));
        break;

      case MessageRole.user:
        if (item.image == null) {
          context.add(ChatMessage.humanText(item.text));
        } else {
          context.add(ChatMessage.human(ChatMessageContent.multiModal([
            ChatMessageContent.text(item.text),
            ChatMessageContent.image(
              mimeType: "image/jpeg",
              data: item.image!,
            ),
          ])));
        }
    }
  }

  return context;
}
