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
import "input.dart";
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "dart:io";
import "dart:async";
import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:langchain/langchain.dart";
import "package:markdown/markdown.dart" as md;
import "package:audioplayers/audioplayers.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:markdown/markdown.dart" hide Element, Text;
import "package:flutter_highlighter/flutter_highlighter.dart";
import "package:flutter_markdown_latex/flutter_markdown_latex.dart";

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
  String? image;
  MessageRole role;

  MessageItem({
    this.time,
    this.image,
    this.model,
    required this.role,
    required this.text,
  });

  factory MessageItem.fromJson(Map json) => switch (json["role"]) {
        "assistant" => MessageItem(
            time: json["time"],
            text: json["text"],
            model: json["model"],
            role: MessageRole.assistant,
          ),
        "user" => MessageItem(
            text: json["text"],
            image: json["image"],
            role: MessageRole.user,
          ),
        _ => throw "bad role",
      };

  Map toJson() => switch (role) {
        MessageRole.assistant => {
            "time": time,
            "text": text,
            "model": model,
            "role": role.name,
          },
        MessageRole.user => {
            "text": text,
            "image": image,
            "role": role.name,
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
  static int _ttsTimes = 0;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    ref.watch(messageProvider(message));

    final Color background;
    final Alignment alignment;
    final CrossAxisAlignment crossAlignment;
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

    final item = message.item;
    var content = item.text;
    final role = item.role;
    if (item.image != null) {
      content = "![image](data:image/jpeg;base64,${item.image})\n\n$content";
    }

    switch (role) {
      case MessageRole.user:
        background = colorScheme.secondaryContainer;
        crossAlignment = CrossAxisAlignment.end;
        alignment = Alignment.topRight;
        break;

      case MessageRole.assistant:
        background = colorScheme.surfaceContainerHighest;
        crossAlignment = CrossAxisAlignment.start;
        alignment = Alignment.topLeft;
        break;
    }

    return Container(
      alignment: alignment,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: crossAlignment,
          children: [
            if (role.isAssistant) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
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
                        item.model ?? CurrentChat.model ?? S.of(context).model,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.time ??
                            CurrentChat.chat?.time ??
                            Util.formatDateTime(DateTime.now()),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  switch (CurrentChat.ttsStatus) {
                    TtsStatus.nothing => IconButton(
                        icon: const Icon(Icons.volume_up_rounded),
                        onPressed: () async => await _tts(context),
                      ),
                    TtsStatus.loading || TtsStatus.playing => IconButton(
                        icon: Icon(CurrentChat.ttsStatus.isPlaying
                            ? Icons.pause_circle_outlined
                            : Icons.cancel_outlined),
                        onPressed: () async {
                          await _ttsStop();
                          setState(
                              () => CurrentChat.ttsStatus = TtsStatus.nothing);
                        },
                      ),
                  }
                ],
              ),
            ],
            SizedBox(height: role.isAssistant ? 8 : 12),
            GestureDetector(
              onLongPress: () async => await _longPress(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: role.isUser
                    ? BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8)
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
                child: MarkdownBody(
                  data: content,
                  shrinkWrap: true,
                  extensionSet: _extensionSet,
                  onTapLink: (text, href, title) async =>
                      await Util.openLink(context: context, link: href),
                  builders: {
                    "pre": _CodeBlockBuilder(context: context),
                    "latex": LatexElementBuilder(textScaleFactor: 1.2),
                  },
                  styleSheet: markdownStyleSheet,
                  styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                ),
              ),
            ),
            if (CurrentChat.messages.lastOrNull == message &&
                CurrentChat.chatStatus.isNothing) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (role.isAssistant)
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            icon: const Icon(Icons.sync_outlined),
                            iconSize: 18,
                            onPressed: () async => await _reanswer(context),
                          ),
                        ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          icon: const Icon(Icons.paste_rounded),
                          iconSize: 16,
                          onPressed: () async => await _copy(context),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 18,
                          onPressed: () async => await _edit(context),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outlined),
                          iconSize: 18,
                          onPressed: () async => await _delete(context),
                        ),
                      ),
                    ],
                  ),
                  if (role.isAssistant && message.list.length > 1)
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded),
                            iconSize: 16,
                            onPressed: () {
                              if (message.index > 0) {
                                setState(() => message.index--);
                              }
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
                              if (message.index + 1 < message.list.length) {
                                setState(() => message.index++);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _tts(BuildContext context) async {
    if (!CurrentChat.ttsStatus.isNothing) return;

    final tts = Config.tts;
    final model = tts.model;
    final voice = tts.voice;
    final api = Config.apis[tts.api];

    if (model == null || voice == null || api == null) {
      if (!context.mounted) return;
      Util.showSnackBar(
        context: context,
        content: Text(
          S.of(context).setup_tts_first,
        ),
      );
      return;
    }

    final apiUrl = api.url;
    final apiKey = api.key;
    final endPoint = "$apiUrl/audio/speech";

    setState(() => CurrentChat.ttsStatus = TtsStatus.loading);
    final times = ++_ttsTimes;

    try {
      final text = widget.message.item.text;
      final response = await http.post(
        Uri.parse(endPoint),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": model,
          "voice": voice,
          "stream": false,
          "input": _markdownToText(text),
        }),
      );

      if (response.statusCode != 200) {
        throw "${response.statusCode} ${response.body}";
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = Config.audioFilePath("$timestamp.mp3");

      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);
      if (CurrentChat.ttsStatus.isNothing || times != _ttsTimes) return;

      await _ttsPlay(path);
      setState(() => CurrentChat.ttsStatus = TtsStatus.playing);
    } catch (e) {
      if (context.mounted) await Util.handleError(context: context, error: e);
      setState(() => CurrentChat.ttsStatus = TtsStatus.nothing);
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Util.copyText(context: context, text: widget.message.item.text);
  }

  Future<void> _edit(BuildContext context) async {
    if (!CurrentChat.chatStatus.isNothing) return;
    if (!CurrentChat.ttsStatus.isNothing) return;
    InputWidget.unFocus();

    final message = widget.message;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _MessageEditor(text: message.item.text),
    );

    if (result != null) {
      setState(() => message.item.text = result);
      await CurrentChat.save();
    }
  }

  Future<void> _delete(BuildContext context) async {
    if (!CurrentChat.chatStatus.isNothing) return;
    if (!CurrentChat.ttsStatus.isNothing) return;

    final message = widget.message;
    final length = message.list.length;

    if (length == 1) {
      CurrentChat.messages.remove(message);
      ref.read(messagesProvider.notifier).notify();
    } else {
      var index = message.index;
      message.list.removeAt(index++);
      setState(() {
        if (index == length) {
          message.index--;
        }
      });
    }

    await CurrentChat.save();
  }

  Future<void> _source(BuildContext context) async {
    InputWidget.unFocus();

    await showModalBottomSheet(
      context: context,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: false,
      scrollControlDisabledMaxHeightRatio: 1,
      builder: (context) {
        return ConstrainedBox(
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
        );
      },
    );
  }

  Future<void> _reanswer(BuildContext context) async {
    if (!CurrentChat.chatStatus.isNothing) return;

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

    final chatContext = buildChatContext(messages);
    final item = MessageItem(
      text: "",
      model: CurrentChat.model,
      role: MessageRole.assistant,
      time: Util.formatDateTime(DateTime.now()),
    );

    final message = widget.message;
    setState(() {
      message.list.add(item);
      message.index = message.list.length - 1;
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
          setState(() => item.text += chunk.output.content);
        }
      } else {
        final result = await llm.invoke(PromptValue.chat(chatContext));
        setState(() => item.text += result.output.content);
      }
    } catch (e) {
      if (context.mounted) await Util.handleError(context: context, error: e);
      if (item.text.isEmpty) {
        setState(() {
          message.list.removeLast();
          message.index--;
        });
      }
    }

    setState(() => CurrentChat.chatStatus = CurrentChatStatus.nothing);
    await CurrentChat.save();
  }

  Future<void> _longPress(BuildContext context) async {
    InputWidget.unFocus();

    final children = [
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
        title: Text(S.of(context).copy),
        leading: const Icon(Icons.copy_all),
        onTap: () => Navigator.pop(context, _LongPressEvent.copy),
      ),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).source),
        leading: const Icon(Icons.code_outlined),
        onTap: () => Navigator.pop(context, _LongPressEvent.source),
      ),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).edit),
        leading: const Icon(Icons.edit_outlined),
        onTap: () => Navigator.pop(context, _LongPressEvent.edit),
      ),
      ListTile(
        minTileHeight: 48,
        shape: StadiumBorder(),
        title: Text(S.of(context).delete),
        leading: const Icon(Icons.delete_outlined),
        onTap: () => Navigator.pop(context, _LongPressEvent.delete),
      ),
    ];

    final event = await showModalBottomSheet<_LongPressEvent>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
      },
    );
    if (event == null || !context.mounted) return;

    switch (event) {
      case _LongPressEvent.copy:
        await _copy(context);
        break;

      case _LongPressEvent.edit:
        await _edit(context);
        break;

      case _LongPressEvent.source:
        await _source(context);
        break;

      case _LongPressEvent.delete:
        await _delete(context);
        break;

      default:
        break;
    }
  }
}

enum _LongPressEvent {
  source,
  delete,
  copy,
  edit,
}

final _extensionSet = ExtensionSet(
  <BlockSyntax>[
    LatexBlockSyntax(),
    const TableSyntax(),
    const FootnoteDefSyntax(),
    const FencedCodeBlockSyntax(),
    const OrderedListWithCheckboxSyntax(),
    const UnorderedListWithCheckboxSyntax(),
  ],
  <InlineSyntax>[
    InlineHtmlSyntax(),
    LatexInlineSyntax(),
    StrikethroughSyntax(),
    AutolinkExtensionSyntax()
  ],
);

String _markdownToText(String markdown) {
  final doc = md.Document(
    extensionSet: _extensionSet,
  );
  final buff = StringBuffer();
  final nodes = doc.parse(markdown);

  for (final node in nodes) {
    if (node is md.Element) {
      buff.write(_elementToText(node));
    }
  }

  return buff.toString().trim();
}

String _elementToText(md.Element element) {
  final buff = StringBuffer();
  final nodes = element.children ?? [];

  if (element.tag == "ul") {
    for (final node in nodes) {
      if (node is md.Element && node.tag == "li") {
        buff.write(_elementToText(node));
      }
    }
  } else if (element.tag == "ol") {
    int index = 1;
    for (final node in nodes) {
      if (node is md.Element && node.tag == "li") {
        buff.write("${index++}. ${_elementToText(node)}");
      }
    }
  } else {
    for (final node in nodes) {
      if (node is md.Text) {
        buff.write(node.text);
      } else if (node is md.Element) {
        final tag = node.tag;
        if (tag == "code") continue;
        if (tag == "latex") continue;
        if (tag == "th" || tag == "td") continue;
        buff.write(_elementToText(node));
      }
      buff.write("\n");
    }
  }

  return buff.toString();
}

extension _Tts on _MessageWidgetState {
  static StreamSubscription? _subscription;
  static final AudioPlayer _player = AudioPlayer();

  Future<void> _ttsPlay(String path) async {
    await _subscription?.cancel();

    _subscription = _player.onPlayerComplete.listen(
      (e) => _ttsClear(),
      onError: (e) => _ttsClear(),
    );

    await _player.play(DeviceFileSource(path));
  }

  Future<void> _ttsStop() async {
    await _player.stop();
  }

  void _ttsClear() {
    CurrentChat.ttsStatus = TtsStatus.nothing;
    ref.read(messageProvider(widget.message).notifier).notify();
  }
}

class _MessageEditor extends StatefulWidget {
  final String text;

  const _MessageEditor({
    required this.text,
  });

  @override
  State<_MessageEditor> createState() => _MessageEditorState();
}

class _MessageEditorState extends State<_MessageEditor> {
  late final UndoHistoryController _undoCtrl;
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _undoCtrl = UndoHistoryController();
    _editCtrl = TextEditingController(text: widget.text);
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            icon: const Icon(Icons.save_outlined),
            onPressed: () => Navigator.of(context).pop(_editCtrl.text),
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
            hintText: S.of(context).enter_your_message,
          ),
        ),
      ),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  var language = "";
  final BuildContext context;

  _CodeBlockBuilder({required this.context});

  @override
  void visitElementBefore(md.Element element) {
    final code = element.children?.first;
    if (code is md.Element) {
      final lang = code.attributes["class"];
      if (lang != null) language = lang.substring(9);
    }
    super.visitElementBefore(element);
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = switch (colorScheme.brightness) {
      Brightness.light => codeLightTheme,
      Brightness.dark => codeDarkTheme,
    };
    final content = text.textContent.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme == codeDarkTheme
                ? Colors.black.withOpacity(0.3)
                : Colors.blueGrey.withOpacity(0.3),
          ),
          padding: EdgeInsets.only(left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language),
              InkWell(
                onTap: () async => await Util.copyText(
                  context: context,
                  text: content,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    S.of(context).copy,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: HighlightView(
            content,
            tabSize: 2,
            theme: theme,
            language: language,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }
}
