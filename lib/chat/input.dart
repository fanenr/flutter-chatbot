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
  static final FocusNode focusNode = FocusNode();

  const InputWidget({
    super.key,
    required this.scrollCtrl,
  });

  @override
  ConsumerState<InputWidget> createState() => _InputWidgetState();

  static void unFocus() => focusNode.unfocus();
}

class _InputWidgetState extends ConsumerState<InputWidget> {
  int _sendTimes = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = CurrentChat.image != null;
    final isResponding = CurrentChat.chatStatus.isResponding;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Badge(
                smallSize: 8,
                isLabelVisible: hasImage,
                child:
                    Icon(hasImage ? Icons.delete : Icons.add_photo_alternate),
              ),
              onPressed: () async {
                if (hasImage) {
                  _clearImage(context);
                } else {
                  await _addImage(context);
                }
              },
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 4),
                child: TextField(
                  maxLines: null,
                  autofocus: false,
                  controller: _inputCtrl,
                  focusNode: InputWidget.focusNode,
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

  Future<void> _addImage(BuildContext context) async {
    InputWidget.unFocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              SizedBox(height: 8),
              ListTile(
                minTileHeight: 48,
                shape: StadiumBorder(),
                title: Text(S.of(context).camera),
                leading: const Icon(Icons.camera_outlined),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                minTileHeight: 48,
                shape: StadiumBorder(),
                title: Text(S.of(context).gallery),
                leading: const Icon(Icons.photo_library_outlined),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final XFile? result;
    Uint8List? compressed;

    try {
      result = await _imagePicker.pickImage(source: source);
      if (result == null) return;
    } catch (e) {
      return;
    }

    try {
      compressed = await FlutterImageCompress.compressWithFile(result.path,
          quality: 60, minWidth: 1024, minHeight: 1024);
      if (compressed == null) throw false;
    } catch (e) {
      if (context.mounted) {
        Util.showSnackBar(
          context: context,
          content: Text(S.of(context).image_compress_failed),
        );
      }
    }

    final bytes = compressed ?? await File(result.path).readAsBytes();
    setState(() => CurrentChat.image = base64Encode(bytes));
  }

  void _clearImage(BuildContext context) {
    setState(() => CurrentChat.image = null);
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (!CurrentChat.chatStatus.isNothing) return;
    final text = _inputCtrl.text;
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

    messages.add(Message.fromItem(MessageItem(
      text: text,
      role: MessageRole.user,
      image: CurrentChat.image,
    )));

    final times = ++_sendTimes;
    final scrollCtrl = widget.scrollCtrl;
    final chatContext = buildChatContext(messages);
    final item = MessageItem(
      text: "",
      model: CurrentChat.model,
      role: MessageRole.assistant,
      time: Util.formatDateTime(DateTime.now()),
    );
    final assistant = Message.fromItem(item);

    messages.add(assistant);
    ref.read(messagesProvider.notifier).notify();
    scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);

    setState(() {
      _inputCtrl.clear();
      CurrentChat.image = null;
      CurrentChat.chatStatus = CurrentChatStatus.responding;
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
          if (CurrentChat.chatStatus.isNothing || times != _sendTimes) return;
          item.text += chunk.output.content;
          ref.read(messageProvider(assistant).notifier).notify();
          scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
        }
      } else {
        final result = await llm.invoke(PromptValue.chat(chatContext));
        if (CurrentChat.chatStatus.isNothing || times != _sendTimes) return;
        item.text += result.output.content;
        ref.read(messageProvider(assistant).notifier).notify();
        scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
      }
    } catch (e) {
      if (CurrentChat.chatStatus.isNothing || times != _sendTimes) return;
      if (context.mounted) await Util.handleError(context: context, error: e);
      if (item.text.isEmpty) {
        messages.length -= 2;
        _inputCtrl.text = text;
        ref.read(messagesProvider.notifier).notify();
      }
    }

    if (await CurrentChat.save()) {
      ref.read(chatProvider.notifier).notify();
      ref.read(chatsProvider.notifier).notify();
    }
    setState(() => CurrentChat.chatStatus = CurrentChatStatus.nothing);
    ref.read(messageProvider(assistant).notifier).notify();
  }

  Future<void> _stopResponding(BuildContext context) async {
    setState(() => CurrentChat.chatStatus = CurrentChatStatus.nothing);
    final list = CurrentChat.messages;

    final user = list[list.length - 2].item;
    final assistant = list.last.item;

    if (assistant.text.isEmpty) {
      list.removeRange(list.length - 2, list.length);
      ref.read(messagesProvider.notifier).notify();
      _inputCtrl.text = user.text;
    } else if (await CurrentChat.save()) {
      ref.read(chatsProvider.notifier).notify();
    }
  }
}

List<ChatMessage> buildChatContext(List<Message> list) {
  final context = <ChatMessage>[];
  final items = [
    for (final message in list) message.item,
  ];
  if (items.last.role.isAssistant) items.removeLast();

  if (CurrentChat.systemPrompts != null) {
    context.add(ChatMessage.system(CurrentChat.systemPrompts!));
  }

  for (final item in items) {
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
        break;
    }
  }

  return context;
}
