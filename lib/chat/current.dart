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
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";

import "dart:io";
import "dart:isolate";
import "dart:convert";
import "dart:typed_data";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

enum TtsStatus {
  nothing,
  loading,
  playing;

  bool get isNothing => this == TtsStatus.nothing;
  bool get isLoading => this == TtsStatus.loading;
  bool get isPlaying => this == TtsStatus.playing;
}

enum ChatStatus {
  nothing,
  responding;

  bool get isNothing => this == ChatStatus.nothing;
  bool get isResponding => this == ChatStatus.responding;
}

class Current {
  static File? file;
  static Uint8List? image;
  static ChatConfig? chat;

  static CoreConfig core = Config.core;
  static final List<Message> messages = [];
  static TtsStatus ttsStatus = TtsStatus.nothing;
  static ChatStatus chatStatus = ChatStatus.nothing;

  static void clear() {
    chat = null;
    file = null;
    image = null;
    messages.clear();
    core = Config.core;
  }

  static Future<void> load(ChatConfig chat) async {
    file = File(Config.chatFilePath(chat.fileName));
    final from = file;

    final json = await Isolate.run(() async {
      return jsonDecode(await from!.readAsString());
    });

    final messagesJson = json["messages"] ?? [];
    final coreJson = json["core"];

    messages.clear();
    for (final message in messagesJson) {
      messages.add(Message.fromJson(message));
    }

    core = coreJson != null ? CoreConfig.fromJson(coreJson) : Config.core;
  }

  static Future<void> save() async {
    if (chat == null) {
      if (messages.isEmpty) return;
      initChat(messages.first.item.text);
    }

    if (file == null) {
      Config.chats.insert(0, chat!);
      Config.save();
      initFile();
    }

    await file!.writeAsString(jsonEncode({
      "core": core,
      "messages": messages,
    }));
  }

  static void initChat(String title) {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();

    final time = Util.formatDateTime(now);
    final fileName = "$timestamp.json";

    chat = ChatConfig(
      time: time,
      title: title,
      fileName: fileName,
    );
  }

  static void initFile() {
    file = File(Config.chatFilePath(chat!.fileName));
  }

  static bool get hasChat => chat != null;
  static bool get hasFile => file != null;

  static String? get bot => core.bot;
  static String? get api => core.api;
  static String? get model => core.model;

  static String? get apiUrl => Config.apis[api]?.url;
  static String? get apiKey => Config.apis[api]?.key;
  static BotConfig? get _bot => Config.bots[core.bot];

  static String? get title => chat?.title;
  static bool? get stream => _bot?.stream;
  static int? get maxTokens => _bot?.maxTokens;
  static double? get temperature => _bot?.temperature;
  static String? get systemPrompts => _bot?.systemPrompts;

  static bool get isOkToChat => api != null && model != null;
}

class ChatSettings extends ConsumerStatefulWidget {
  const ChatSettings({super.key});

  @override
  ConsumerState<ChatSettings> createState() => ChatSettingsState();
}

class ChatSettingsState extends ConsumerState<ChatSettings> {
  String? _bot = Current.bot;
  String? _api = Current.api;
  String? _model = Current.model;
  final TextEditingController _titleCtrl =
      TextEditingController(text: Current.title);

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botList = <DropdownMenuItem<String>>[];
    final apiList = <DropdownMenuItem<String>>[];
    final modelList = <DropdownMenuItem<String>>[];

    final bots = Config.bots.keys;
    final apis = Config.apis.keys;
    final models = Config.apis[_api]?.models ?? [];

    for (final bot in bots) {
      botList.add(DropdownMenuItem(
        value: bot,
        child: Text(bot, overflow: TextOverflow.ellipsis),
      ));
    }

    for (final api in apis) {
      apiList.add(DropdownMenuItem(
        value: api,
        child: Text(api, overflow: TextOverflow.ellipsis),
      ));
    }

    for (final model in models) {
      modelList.add(DropdownMenuItem(
        value: model,
        child: Text(model, overflow: TextOverflow.ellipsis),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).chat_settings),
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: S.of(context).chat_title,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _bot,
                    items: botList,
                    isExpanded: true,
                    hint: Text(S.of(context).bot),
                    onChanged: (it) => setState(() => _bot = it),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _api,
                    items: apiList,
                    isExpanded: true,
                    hint: Text(S.of(context).api),
                    onChanged: (it) => setState(() {
                      _model = null;
                      _api = it;
                    }),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _model,
              items: modelList,
              isExpanded: true,
              menuMaxHeight: 480,
              hint: Text(S.of(context).model),
              onChanged: (it) => setState(() => _model = it),
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    child: Text(S.of(context).reset),
                    onPressed: () => setState(() {
                      _model = null;
                      _api = null;
                      _bot = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(S.of(context).save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text;
    final oldModel = Current.model;
    final oldTitle = Current.title;

    if (title.isEmpty && Current.hasChat) {
      Util.showSnackBar(
        context: context,
        content: Text(S.of(context).enter_a_title),
      );
      return;
    }

    if (Current.hasChat) {
      Current.chat!.title = title;
    } else if (title.isNotEmpty) {
      Current.initChat(title);
    }

    Current.core = CoreConfig(
      bot: _bot,
      api: _api,
      model: _model,
    );
    Current.save();

    if (title != oldTitle && Current.hasFile) {
      ref.read(chatsProvider.notifier).notify();
    }
    if (title != oldTitle || _model != oldModel) {
      ref.read(chatProvider.notifier).notify();
    }
    if (mounted) Navigator.of(context).pop();
  }
}
