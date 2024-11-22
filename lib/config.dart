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

import "dart:convert";
import "dart:io";

import "package:archive/archive_io.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_highlighter/themes/atom-one-dark.dart";
import "package:flutter_highlighter/themes/atom-one-light.dart";
import "package:media_store_plus/media_store_plus.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";

class CoreConfig {
  String? bot;
  String? api;
  String? model;

  CoreConfig({
    this.bot,
    this.api,
    this.model,
  });

  Map toJson() => {
        "bot": bot,
        "api": api,
        "model": model,
      };

  factory CoreConfig.fromJson(Map json) => CoreConfig(
        bot: json["bot"],
        api: json["api"],
        model: json["model"],
      );
}

class TtsConfig {
  String? api;
  String? model;
  String? voice;

  TtsConfig({
    this.api,
    this.model,
    this.voice,
  });

  Map toJson() => {
        "api": api,
        "model": model,
        "voice": voice,
      };

  factory TtsConfig.fromJson(Map json) => TtsConfig(
        api: json["api"],
        model: json["model"],
        voice: json["voice"],
      );
}

class ChatConfig {
  String time;
  String title;
  String fileName;

  ChatConfig({
    required this.time,
    required this.title,
    required this.fileName,
  });

  Map toJson() => {
        "time": time,
        "title": title,
        "fileName": fileName,
      };

  factory ChatConfig.fromJson(Map json) => ChatConfig(
        time: json["time"],
        title: json["title"],
        fileName: json["fileName"],
      );
}

class BotConfig {
  bool? stream;
  int? maxTokens;
  double? temperature;
  String? systemPrompts;

  BotConfig({
    this.stream,
    this.maxTokens,
    this.temperature,
    this.systemPrompts,
  });

  Map toJson() => {
        "stream": stream,
        "maxTokens": maxTokens,
        "temperature": temperature,
        "systemPrompts": systemPrompts,
      };

  factory BotConfig.fromJson(Map json) => BotConfig(
        stream: json["stream"],
        maxTokens: json["maxTokens"],
        temperature: json["temperature"],
        systemPrompts: json["systemPrompts"],
      );
}

class ApiConfig {
  String url;
  String key;
  List<String> models;

  ApiConfig({
    required this.url,
    required this.key,
    required this.models,
  });

  Map toJson() => {
        "url": url,
        "key": key,
        "models": models,
      };

  factory ApiConfig.fromJson(Map json) => ApiConfig(
        url: json["url"],
        key: json["key"],
        models: json["models"].cast<String>(),
      );
}

class Config {
  static late final TtsConfig tts;
  static late final CoreConfig core;
  static final List<ChatConfig> chats = [];
  static final Map<String, BotConfig> bots = {};
  static final Map<String, ApiConfig> apis = {};

  static late final File _file;
  static late final String _dir;
  static late final String _cacheDir;
  static late final String _sep;

  static const String _chatDir = "chat";
  static const String _audioDir = "audio";
  static const String _settingsFile = "settings.json";

  static Future<void> init() async {
    _sep = Platform.pathSeparator;
    _cacheDir = (await getApplicationCacheDirectory()).path;
    if (Platform.isAndroid) {
      _dir = (await getExternalStorageDirectory())!.path;
      MediaStore.ensureInitialized();
      MediaStore.appFolder = "ChatBot";
    } else {
      _dir = (await getApplicationSupportDirectory()).path;
    }

    await _initDir();
    await _initFile();
    await _fixChatFile();
  }

  static Future<void> save() async {
    await _file.writeAsString(jsonEncode(toJson()));
  }

  static String chatFilePath(String fileName) =>
      "$_dir$_sep$_chatDir$_sep$fileName";
  static String audioFilePath(String fileName) =>
      "$_dir$_sep$_audioDir$_sep$fileName";

  static Map toJson() => {
        "tts": tts,
        "core": core,
        "bots": bots,
        "apis": apis,
        "chats": chats,
      };

  static void fromJson(Map json) {
    final ttsJson = json["tts"] ?? {};
    final coreJson = json["core"] ?? {};
    final botsJson = json["bots"] ?? {};
    final apisJson = json["apis"] ?? {};
    final chatsJson = json["chats"] ?? [];

    tts = TtsConfig.fromJson(ttsJson);
    core = CoreConfig.fromJson(coreJson);

    for (final chat in chatsJson) {
      chats.add(ChatConfig.fromJson(chat));
    }
    for (final pair in botsJson.entries) {
      bots[pair.key] = BotConfig.fromJson(pair.value);
    }
    for (final pair in apisJson.entries) {
      apis[pair.key] = ApiConfig.fromJson(pair.value);
    }
  }

  static Future<void> _initDir() async {
    final audioPath = "$_dir$_sep$_audioDir";
    final audioDir = Directory(audioPath);
    if (!(await audioDir.exists())) {
      await audioDir.create();
    }

    final chatPath = "$_dir$_sep$_chatDir";
    final chatDir = Directory(chatPath);
    if (!(await chatDir.exists())) {
      await chatDir.create();
    }
  }

  static Future<void> _initFile() async {
    final path = "$_dir$_sep$_settingsFile";
    _file = File(path);

    if (await _file.exists()) {
      final data = await _file.readAsString();
      fromJson(jsonDecode(data));
    } else {
      core = CoreConfig();
      tts = TtsConfig();
      save();
    }
  }

  static Future<void> _fixChatFile() async {
    for (final chat in chats) {
      final fileName = chat.fileName;
      final oldPath = "$_dir$_sep$fileName";
      final newPath = chatFilePath(fileName);

      final file = File(oldPath);
      if (await file.exists()) {
        await file.rename(newPath);
      }
    }
  }
}

class Backup {
  static Future<bool> exportConfig() async {
    if (Platform.isAndroid) {
      if (!(await Permission.storage.request().isGranted)) {
        return false;
      }
    }

    final time = DateTime.now().millisecondsSinceEpoch.toString();
    String fileName = "chatbot-backup-$time.zip";
    final path = "${Config._cacheDir}${Config._sep}$fileName";

    try {
      final dir = Directory(Config._dir);
      final encoder = ZipFileEncoder();
      encoder.create(path);

      await for (final entity in dir.list()) {
        if (entity is File) {
          encoder.addFile(entity);
        } else if (entity is Directory) {
          encoder.addDirectory(entity);
        }
      }

      await encoder.close();

      var zipFile = File(path);
      if (await zipFile.exists()) {
        // 复制文件到下载目录
        if (Platform.isAndroid) {
          await MediaStore().saveFile(
              tempFilePath: path,
              dirType: DirType.download,
              dirName: DirName.download);
        } else {
          final downloadDirectory = Directory(Config._dir);
          zipFile.copy("${downloadDirectory.path}${Config._sep}$fileName");
        }
      }
    } catch (e) {
      print(e);
      rethrow;
    }

    return true;
  }

  static Future<bool> importConfig() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return false;

    try {
      final path = result.files.single.path!;
      await extractFileToDisk(path, Config._dir);
    } catch (e) {
      rethrow;
    }

    return true;
  }
}

const _baseColor = Colors.indigo;

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: _baseColor,
);

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.light,
  seedColor: _baseColor,
);

final darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
  colorScheme: darkColorScheme,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: darkColorScheme.surface,
  ),
  appBarTheme: AppBarTheme(color: darkColorScheme.primaryContainer),
);

final lightTheme = ThemeData.light(useMaterial3: true).copyWith(
  colorScheme: lightColorScheme,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: lightColorScheme.surface,
  ),
  appBarTheme: AppBarTheme(color: lightColorScheme.primaryContainer),
);

final codeDarkTheme = Map.of(atomOneDarkTheme)
  ..["root"] = TextStyle(
      color: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.transparent);

final codeLightTheme = Map.of(atomOneLightTheme)
  ..["root"] = TextStyle(
      color: Colors.black.withOpacity(0.7),
      backgroundColor: Colors.transparent);
