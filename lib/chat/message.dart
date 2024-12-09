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

import "llm.dart";
import "chat.dart";
import "input.dart";
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../markdown/all.dart";

import "dart:async";
import "dart:convert";
import "dart:typed_data";
import "package:flutter/material.dart";
import "package:animate_do/animate_do.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_markdown/flutter_markdown.dart";

final messageProvider = NotifierProvider.autoDispose
    .family<MessageNotifier, void, Message>(MessageNotifier.new);

class MessageNotifier extends AutoDisposeFamilyNotifier<void, Message> {
  @override
  void build(Message arg) {}

  void notify() => ref.notifyListeners();
}

enum MessageRole {
  assistant,
  user;

  bool get isAssistant => this == MessageRole.assistant;
  bool get isUser => this == MessageRole.user;
}

class MessageItem {
  String text;
  String? time;
  String? model;
  Uint8List? image;
  MessageRole role;
  String? imageBase64;

  MessageItem({
    this.time,
    this.image,
    this.model,
    this.imageBase64,
    required this.role,
    required this.text,
  }) {
    if (image != null) {
      imageBase64 = base64Encode(image!);
    } else if (imageBase64 != null) {
      image = base64Decode(imageBase64!);
    }
  }

  factory MessageItem.fromJson(Map json) => switch (json["role"]) {
        "assistant" => MessageItem(
            time: json["time"],
            text: json["text"],
            model: json["model"],
            role: MessageRole.assistant,
          ),
        "user" => MessageItem(
            text: json["text"],
            role: MessageRole.user,
            imageBase64: json["image"],
          ),
        _ => throw "bad role",
      };

  Map toJson() => switch (role) {
        MessageRole.assistant => {
            "time": time,
            "text": text,
            "model": model,
            "role": "assistant",
          },
        MessageRole.user => {
            "text": text,
            "role": "user",
            "image": imageBase64,
          },
      };
}

class Message {
  int index;
  List<MessageItem> list;

  Message({
    required this.index,
    required this.list,
  });

  factory Message.fromItem(MessageItem item) => Message(index: 0, list: [item]);

  factory Message.fromJson(Map json) =>
      json["index"] == null && json["list"] == null
          ? Message(index: 0, list: [MessageItem.fromJson(json)])
          : Message(
              index: json["index"],
              list: [
                for (final item in json["list"]) MessageItem.fromJson(item),
              ],
            );

  Map toJson() => {
        "index": index,
        "list": list,
      };

  MessageItem get item => list[index];
}

class MessageWidget extends ConsumerStatefulWidget {
  final Message message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends ConsumerState<MessageWidget> {
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    ref.watch(messageProvider(message));

    final item = message.item;
    var content = item.text;
    final role = item.role;

    final colorScheme = Theme.of(context).colorScheme;
    final markdownStyleSheet = MarkdownStyleSheet(
      codeblockPadding: EdgeInsets.all(0),
      codeblockDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.surfaceContainer,
      ),
      blockquoteDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.brightness == Brightness.light
            ? Colors.blueGrey.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
      ),
    );

    final background = role.isUser
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;

    return Container(
      alignment: role.isUser ? Alignment.topRight : Alignment.topLeft,
      child: Column(
        crossAxisAlignment: role.isAssistant
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (role.isAssistant) ...[
            const SizedBox(height: 12),
            _buildHeader(message, item),
          ],
          SizedBox(height: role.isAssistant ? 8 : 16),
          if (item.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: Image.memory(
                item.image!,
                fit: BoxFit.cover,
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onLongPress: _longPress,
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: role.isUser
                  ? BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    )
                  : null,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                  topRight: Radius.circular(role.isUser ? 2 : 16),
                ),
              ),
              child: switch (item.text.isNotEmpty) {
                true => MarkdownBody(
                    data: content,
                    shrinkWrap: true,
                    extensionSet: mdExtensionSet,
                    onTapLink: (text, href, title) =>
                        Dialogs.openLink(context: context, link: href),
                    builders: {
                      "pre": CodeBlockBuilder(context: context),
                      "latex": LatexElementBuilder(textScaleFactor: 1.2),
                    },
                    styleSheet: markdownStyleSheet,
                    styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                  ),
                false => SizedBox(
                    width: 36,
                    height: 18,
                    child: SpinKitWave(
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              },
            ),
          ),
          if (Current.messages.lastOrNull == message &&
              Current.chatStatus.isNothing) ...[
            const SizedBox(height: 4),
            FadeIn(child: _buildToolBar(role)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Message message, MessageItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          child: const Icon(Icons.smart_toy),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.model ?? Current.model ?? S.of(context).no_model,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.time ??
                    Current.chat?.time ??
                    Util.formatDateTime(DateTime.now()),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        if (message.list.length > 1 &&
            (Current.chatStatus.isNothing ||
                message != Current.messages.lastOrNull)) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              iconSize: 16,
              onPressed: () {
                if (item == message.list.first) return;
                setState(() => message.index--);
                Current.save();
              },
            ),
          ),
          Text("${message.index + 1}/${message.list.length}"),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              iconSize: 16,
              onPressed: () {
                if (item == message.list.last) return;
                setState(() => message.index++);
                Current.save();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToolBar(MessageRole role) {
    return Row(
      mainAxisAlignment:
          role.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (role.isAssistant) ...[
          SizedBox(
            width: 36,
            height: 26,
            child: IconButton(
              icon: Icon(switch (Current.ttsStatus) {
                TtsStatus.loading => Icons.cancel_outlined,
                TtsStatus.nothing => Icons.volume_up_outlined,
                TtsStatus.playing => Icons.pause_circle_outlined,
              }),
              iconSize: 18,
              onPressed: _tts,
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(
            width: 36,
            height: 26,
            child: IconButton(
              icon: const Icon(Icons.sync_outlined),
              iconSize: 18,
              onPressed: _reanswer,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        SizedBox(
          width: 36,
          height: 26,
          child: IconButton(
            icon: const Icon(Icons.paste_outlined),
            iconSize: 16,
            onPressed: _copy,
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(
          width: 36,
          height: 26,
          child: IconButton(
            icon: const Icon(Icons.edit_outlined),
            iconSize: 18,
            onPressed: _edit,
            padding: EdgeInsets.zero,
          ),
        ),
        SizedBox(
          width: 36,
          height: 26,
          child: IconButton(
            icon: const Icon(Icons.delete_outlined),
            iconSize: 18,
            onPressed: _delete,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _tts() async {
    if (!Current.ttsStatus.isNothing) {
      ref.read(llmProvider.notifier).stopTts();
      return;
    }

    final message = widget.message;
    final text = message.item.text;
    if (text.isEmpty) return;

    if (!Config.isOkToTts) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_tts_first),
      );
      return;
    }

    final error = await ref.read(llmProvider.notifier).tts(message);
    if (error != null && mounted) {
      Dialogs.error(context: context, error: error);
    }
  }

  void _copy() {
    Util.copyText(context: context, text: widget.message.item.text);
  }

  void _edit() {
    InputWidget.unFocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _MessageEditor(message: widget.message),
    ));
  }

  void _delete() {
    if (!Current.chatStatus.isNothing) return;
    if (!Current.ttsStatus.isNothing) return;

    final message = widget.message;
    final list = message.list;
    final item = message.item;

    if (list.length == 1) {
      Current.messages.remove(message);
      ref.read(messagesProvider.notifier).notify();
    } else {
      if (item == list.last) message.index--;
      setState(() => list.remove(item));
    }

    Current.save();
  }

  void _source() {
    InputWidget.unFocus();

    showModalBottomSheet(
      context: context,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 1,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      top: 0, left: 16, right: 16, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        widget.message.item.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 48, width: double.infinity),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reanswer() async {
    if (!Current.chatStatus.isNothing) {
      ref.read(llmProvider.notifier).stopChat();
      return;
    }

    if (!Current.isOkToChat) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).setup_api_model_first),
      );
      return;
    }

    final message = widget.message;
    message.list.add(MessageItem(
      text: "",
      model: Current.model,
      role: MessageRole.assistant,
      time: Util.formatDateTime(DateTime.now()),
    ));
    message.index = message.list.length - 1;
    final error = await ref.read(llmProvider.notifier).chat(message);

    if (error != null && mounted) {
      Dialogs.error(context: context, error: error);
    }
  }

  Future<void> _longPress() async {
    InputWidget.unFocus();

    final event = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              minTileHeight: 48,
              shape: StadiumBorder(),
              title: Text(S.of(context).copy),
              leading: const Icon(Icons.copy_all),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).edit),
              leading: const Icon(Icons.edit_outlined),
              onTap: () => Navigator.pop(context, 2),
            ),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).source),
              leading: const Icon(Icons.code_outlined),
              onTap: () => Navigator.pop(context, 3),
            ),
            ListTile(
              minTileHeight: 48,
              shape: const StadiumBorder(),
              title: Text(S.of(context).delete),
              leading: const Icon(Icons.delete_outlined),
              onTap: () => Navigator.pop(context, 4),
            ),
          ],
        ),
      ),
    );
    if (event == null || !context.mounted) return;

    switch (event) {
      case 1:
        _copy();
        break;

      case 2:
        _edit();
        break;

      case 3:
        _source();
        break;

      case 4:
        _delete();
        break;
    }
  }
}

class MessageView extends StatelessWidget {
  final Message message;

  const MessageView({
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final item = message.item;
    var content = item.text;
    final role = item.role;

    final colorScheme = Theme.of(context).colorScheme;
    final markdownStyleSheet = MarkdownStyleSheet(
      codeblockPadding: EdgeInsets.all(0),
      codeblockDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.surfaceContainer,
      ),
      blockquoteDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: colorScheme.brightness == Brightness.light
            ? Colors.blueGrey.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
      ),
    );

    final background = role.isUser
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;

    return Container(
      alignment: role.isUser ? Alignment.topRight : Alignment.topLeft,
      child: Column(
        crossAxisAlignment: role.isAssistant
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (role.isAssistant) ...[
            const SizedBox(height: 12),
            _buildHeader(context, message, item),
          ],
          SizedBox(height: role.isAssistant ? 8 : 16),
          if (item.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              child: Image.memory(
                item.image!,
                fit: BoxFit.cover,
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            constraints: role.isUser
                ? BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  )
                : null,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
                topRight: Radius.circular(role.isUser ? 2 : 16),
              ),
            ),
            child: switch (item.text.isNotEmpty) {
              true => MarkdownBody(
                  data: content,
                  extensionSet: mdExtensionSet,
                  onTapLink: (text, href, title) =>
                      Dialogs.openLink(context: context, link: href),
                  builders: {
                    "pre": CodeBlockBuilder2(context: context),
                    "latex": LatexElementBuilder2(textScaleFactor: 1.2),
                  },
                  styleSheet: markdownStyleSheet,
                  styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                ),
              false => SizedBox(
                  width: 36,
                  height: 18,
                  child: SpinKitWave(
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Message message, MessageItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          child: const Icon(Icons.smart_toy),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.model ?? Current.model ?? S.current.no_model,
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item.time ??
                  Current.chat?.time ??
                  Util.formatDateTime(DateTime.now()),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _MessageEditor extends ConsumerStatefulWidget {
  final Message message;

  const _MessageEditor({
    required this.message,
  });

  @override
  ConsumerState<_MessageEditor> createState() => _MessageEditorState();
}

class _MessageEditorState extends ConsumerState<_MessageEditor> {
  late final Message message;
  late final UndoHistoryController _undoCtrl;
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    message = widget.message;
    _undoCtrl = UndoHistoryController();
    final text = widget.message.item.text;
    _editCtrl = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    _undoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).edit),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _undoCtrl.undo(),
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: () => _undoCtrl.redo(),
          ),
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              message.item.text = _editCtrl.text;
              ref.read(messageProvider(message).notifier).notify();

              Current.save();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
        child: TextField(
          expands: true,
          maxLines: null,
          controller: _editCtrl,
          undoController: _undoCtrl,
          textAlign: TextAlign.start,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: S.of(context).enter_message,
          ),
        ),
      ),
    );
  }
}
