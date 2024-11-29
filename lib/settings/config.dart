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

import "bot.dart";
import "api.dart";
import "../util.dart";
import "../config.dart";
import "../gen/l10n.dart";
import "../chat/chat.dart";

import "dart:io";
import "package:flutter/services.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ConfigTab extends ConsumerStatefulWidget {
  const ConfigTab({super.key});

  @override
  ConsumerState<ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends ConsumerState<ConfigTab> {
  @override
  Widget build(BuildContext context) {
    ref.watch(botsProvider);
    ref.watch(apisProvider);

    final s = S.of(context);
    const padding = EdgeInsets.only(left: 24, right: 24);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ListView(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: padding,
          child: Text(
            s.default_config,
            style: TextStyle(color: primaryColor),
          ),
        ),
        ListTile(
          title: Text(s.bot),
          contentPadding: padding,
          subtitle: Text(Config.core.bot ?? s.empty),
          onTap: () async {
            final bot = await _select(
              list: Config.bots.keys.toList(),
              selected: Config.core.bot,
              title: s.choose_bot,
            );
            if (bot == null) return;

            setState(() => Config.core.bot = bot);
            await Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.api),
          contentPadding: padding,
          subtitle: Text(Config.core.api ?? s.empty),
          onTap: () async {
            final api = await _select(
              list: Config.apis.keys.toList(),
              selected: Config.core.api,
              title: s.choose_api,
            );
            if (api == null) return;

            setState(() => Config.core.api = api);
            ref.read(chatProvider.notifier).notify();
            await Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.model),
          contentPadding: padding,
          subtitle: Text(Config.core.model ?? s.empty),
          onTap: () async {
            final models = Config.apis[Config.core.api]?.models;
            if (models == null) return;

            final model = await _select(
              selected: Config.core.model,
              title: s.choose_model,
              list: models,
            );
            if (model == null) return;

            setState(() => Config.core.model = model);
            ref.read(chatProvider.notifier).notify();
            await Config.save();
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: padding,
          child: Text(
            s.text_to_speech,
            style: TextStyle(color: primaryColor),
          ),
        ),
        ListTile(
          title: Text(s.api),
          contentPadding: padding,
          subtitle: Text(Config.tts.api ?? s.empty),
          onTap: () async {
            final api = await _select(
              list: Config.apis.keys.toList(),
              selected: Config.tts.api,
              title: s.choose_api,
            );
            if (api == null) return;

            setState(() => Config.tts.api = api);
            await Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.model),
          contentPadding: padding,
          subtitle: Text(Config.tts.model ?? s.empty),
          onTap: () async {
            final models = Config.apis[Config.tts.api]?.models;
            if (models == null) return;

            final model = await _select(
              selected: Config.tts.model,
              title: s.choose_model,
              list: models,
            );
            if (model == null) return;

            setState(() => Config.tts.model = model);
            await Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.voice),
          contentPadding: padding,
          subtitle: Text(Config.tts.voice ?? s.empty),
          onTap: () async {
            var text = await _input(
              title: s.voice,
              hint: s.please_input,
              text: Config.tts.voice,
            );
            if (text == null) return;

            String? voice;
            text = text.trim();
            if (text.isNotEmpty) voice = text;

            setState(() => Config.tts.voice = voice);
            await Config.save();
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: padding,
          child: Text(
            s.chat_image_compress,
            style: TextStyle(color: primaryColor),
          ),
        ),
        CheckboxListTile(
          title: Text(s.enable),
          contentPadding: padding,
          value: Config.img.enable ?? true,
          subtitle: Text(s.image_enable_hint),
          onChanged: (value) async {
            setState(() => Config.img.enable = value);
            await Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.quality),
          contentPadding: padding,
          subtitle: Text(Config.img.quality?.toString() ?? s.empty),
          onTap: () async {
            var text = await _input(
              title: s.quality,
              hint: s.please_input,
              text: Config.img.quality?.toString(),
            );
            if (text == null) return;

            int? quality;
            text = text.trim();
            if (text.isNotEmpty) {
              quality = int.tryParse(text);
              if (quality == null) return;
            }

            setState(() => Config.img.quality = quality);
            await Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.min_width),
          contentPadding: padding,
          subtitle: Text(Config.img.minWidth?.toString() ?? s.empty),
          onTap: () async {
            var text = await _input(
              title: s.min_width,
              hint: s.please_input,
              text: Config.img.minWidth?.toString(),
            );
            if (text == null) return;

            int? minWidth;
            text = text.trim();
            if (text.isNotEmpty) {
              minWidth = int.tryParse(text);
              if (minWidth == null) return;
            }

            setState(() => Config.img.minWidth = minWidth);
            await Config.save();
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.min_height),
          contentPadding: padding,
          subtitle: Text(Config.img.minHeight?.toString() ?? s.empty),
          onTap: () async {
            var text = await _input(
              title: s.min_height,
              hint: s.please_input,
              text: Config.img.minHeight?.toString(),
            );
            if (text == null) return;

            int? minHeight;
            text = text.trim();
            if (text.isNotEmpty) {
              minHeight = int.tryParse(text);
              if (minHeight == null) return;
            }

            setState(() => Config.img.minHeight = minHeight);
            await Config.save();
          },
        ),
        Card.outlined(
          margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
          child: Padding(
            padding:
                const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.image_hint,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: padding,
          child: Text(
            s.config_import_export,
            style: TextStyle(color: primaryColor),
          ),
        ),
        ListTile(
          title: Text(s.import_config),
          contentPadding: padding,
          onTap: () async {
            try {
              final result = await Backup.importConfig();
              if (!result || !context.mounted) return;

              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.imported_successfully),
                  content: Text(s.restart_app),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.ok),
                    )
                  ],
                ),
              );

              await SystemNavigator.pop();
            } catch (e) {
              if (!context.mounted) return;
              await Util.handleError(context: context, error: e);
            }
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(s.export_config),
          contentPadding: padding,
          onTap: () async {
            try {
              final result = await Backup.exportConfig();
              if (!result || !context.mounted) return;

              Util.showSnackBar(
                context: context,
                content: Text(s.exported_successfully),
              );
            } on PathAccessException {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.error),
                  content: Text(s.failed_to_export),
                  actions: [
                    TextButton(
                      child: Text(s.ok),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            } catch (e) {
              await Util.handleError(context: context, error: e);
            }
          },
        ),
        Card.outlined(
          margin:
              const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 16),
          child: Padding(
            padding:
                const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.config_hint,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _select({
    required List<String> list,
    required String title,
    String? selected,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: Divider(),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) => RadioListTile(
                    value: list[index],
                    groupValue: selected,
                    title: Text(list[index]),
                    contentPadding: const EdgeInsets.only(left: 16, right: 24),
                    onChanged: (value) => setState(() => selected = value),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(S.of(context).cancel),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    child: Text(S.of(context).ok),
                    onPressed: () => Navigator.of(context).pop(selected),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _input({
    required String title,
    String? text,
    String? hint,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: _InputDialog(
          title: title,
          text: text,
          hint: hint,
        ),
      ),
    );
  }
}

class _InputDialog extends StatefulWidget {
  final String title;
  final String? text;
  final String? hint;

  const _InputDialog({
    required this.title,
    this.text,
    this.hint,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: widget.hint,
              border: UnderlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            TextButton(
              child: Text(S.of(context).ok),
              onPressed: () => Navigator.of(context).pop(ctrl.text),
            ),
            const SizedBox(width: 24),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
