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

import "input.dart";
import "message.dart";
import "current.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../settings/api.dart";

import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

final chatProvider =
    NotifierProvider.autoDispose<ChatNotifier, void>(ChatNotifier.new);

final chatsProvider =
    NotifierProvider.autoDispose<ChatsNotifier, void>(ChatsNotifier.new);

final messagesProvider =
    NotifierProvider.autoDispose<MessagesNotifier, void>(MessagesNotifier.new);

class ChatNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() => ref.listen(apisProvider, (p, n) => notify());
  void notify() => ref.notifyListeners();
}

class ChatsNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}
  void notify() => ref.notifyListeners();
}

class MessagesNotifier extends AutoDisposeNotifier<void> {
  @override
  void build() {}
  void notify() => ref.notifyListeners();
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(child: _buildDrawer()),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    ref.watch(messagesProvider);

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(
                          top: 4, left: 16, right: 16, bottom: 16),
                      itemCount: CurrentChat.messages.length,
                      itemBuilder: (context, index) {
                        final message = CurrentChat.messages[index];
                        return MessageWidget(
                          message: message,
                          key: ValueKey(message),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          InputWidget(scrollCtrl: _scrollCtrl),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(children: [
        Flexible(
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(chatProvider);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrentChat.title ?? S.of(context).new_chat,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    CurrentChat.model ?? S.of(context).no_model,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  )
                ],
              );
            },
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            ref.watch(chatProvider);

            return PopupMenuButton<String>(
              icon: const Icon(Icons.swap_vert),
              onSelected: (value) async {
                InputWidget.unFocus();
                CurrentChat.core = CoreConfig(
                  bot: CurrentChat.bot,
                  api: CurrentChat.api,
                  model: value,
                );
                ref.read(chatProvider.notifier).notify();
                await CurrentChat.save();
              },
              itemBuilder: (context) {
                final models = Config.apis[CurrentChat.api]?.models ?? [];
                final modelList = <PopupMenuItem<String>>[];
                for (final model in models) {
                  modelList.add(PopupMenuItem(
                    value: model,
                    child: Text(model),
                  ));
                }
                return modelList;
              },
              iconSize: 18,
            );
          },
        ),
      ]),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            InputWidget.unFocus();
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) async => await _onSelected(context, value),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          itemBuilder: (context) => <PopupMenuItem<int>>[
            PopupMenuItem(
              value: 1,
              child: ListTile(
                leading: const Icon(Icons.file_copy, size: 20),
                title: Text(S.of(context).clone_chat),
                minTileHeight: 32,
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: ListTile(
                leading: const Icon(Icons.delete, size: 24),
                title: Text(S.of(context).clear_chat),
                minTileHeight: 32,
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: ListTile(
                leading: const Icon(Icons.settings, size: 24),
                title: Text(S.of(context).chat_settings),
                minTileHeight: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Column(
      children: [
        ListTile(
          title: Text(
            "ChatBot",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed("/settings"),
          ),
          contentPadding: const EdgeInsets.only(left: 16, right: 8),
        ),
        Divider(),
        Container(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: ListTile(
            minTileHeight: 48,
            shape: const StadiumBorder(),
            title: Text(S.of(context).new_chat),
            leading: const Icon(Icons.post_add),
            onTap: () {
              if (CurrentChat.chatStatus.isResponding) return;
              CurrentChat.clear();
              ref.read(chatProvider.notifier).notify();
              ref.read(chatsProvider.notifier).notify();
              ref.read(messagesProvider.notifier).notify();
            },
          ),
        ),
        Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            S.of(context).all_chats,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(chatsProvider);

              return ListView.builder(
                padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                itemCount: Config.chats.length,
                itemBuilder: (context, index) => _buildChatItem(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatItem(int index) {
    final chat = Config.chats[index];

    return Container(
      margin: EdgeInsets.only(top: 4),
      child: ListTile(
        dense: true,
        minTileHeight: 48,
        shape: const StadiumBorder(),
        leading: const Icon(Icons.article),
        selected: CurrentChat.chat == chat,
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(
          chat.title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(chat.time),
        onTap: () async {
          if (CurrentChat.chat == chat) return;

          await CurrentChat.load(chat);
          ref.read(chatProvider.notifier).notify();
          ref.read(chatsProvider.notifier).notify();
          ref.read(messagesProvider.notifier).notify();
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            if (CurrentChat.chat == chat) {
              CurrentChat.clear();
              ref.read(chatProvider.notifier).notify();
              ref.read(messagesProvider.notifier).notify();
            }

            await File(Config.chatFilePath(chat.fileName)).delete();
            ref.read(chatsProvider.notifier).notify();
            Config.chats.removeAt(index);
            await Config.save();
          },
        ),
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, int value) async {
    InputWidget.unFocus();

    switch (value) {
      case 1:
        if (!CurrentChat.hasChat || !CurrentChat.hasFile) return;

        CurrentChat.file = null;
        CurrentChat.initChat(CurrentChat.title!);

        await CurrentChat.save();
        ref.read(chatsProvider.notifier).notify();

        if (!context.mounted) return;
        Util.showSnackBar(
          context: context,
          content: Text(S.of(context).cloned_successfully),
        );
        break;

      case 2:
        if (!CurrentChat.hasChat || !CurrentChat.hasFile) return;

        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(S.of(context).clear_chat),
            content: Text(S.of(context).ensure_clear_chat),
            actions: [
              TextButton(
                child: Text(S.of(context).cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(S.of(context).clear),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
        if (!(result ?? false)) return;
        CurrentChat.messages.clear();

        await CurrentChat.save();
        ref.read(messagesProvider.notifier).notify();
        break;

      case 3:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CurrentChatSettings(),
        ));
        break;
    }
  }
}
