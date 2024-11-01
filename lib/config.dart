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

import "dart:io";
import "dart:convert";
import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import "package:flutter_highlighter/themes/atom-one-dark.dart";
import "package:flutter_highlighter/themes/atom-one-light.dart";

class ConfigBot {
  String? api;
  String? model;
  int maxTokens = 1024;
  num temperature = 0.7;
  String systemPrompts = "";
}

class ConfigAPI {
  String url;
  String key;
  List<String> models;

  ConfigAPI({
    required this.url,
    required this.key,
    required this.models,
  });
}

class Config {
  static late final ConfigBot bot;
  static late final Map<String, ConfigAPI> apis;

  static String? get apiUrl {
    if (bot.api == null) return null;
    return apis[bot.api]!.url;
  }

  static String? get apiKey {
    if (bot.api == null) return null;
    return apis[bot.api]!.key;
  }

  static bool get isOk {
    return bot.model != null && apiUrl != null && apiKey != null;
  }

  static bool get isNotOk {
    return bot.model == null || apiUrl == null || apiKey == null;
  }

  static void fromJson(Map<String, dynamic> json) {
    final botJson = json["bot"];
    bot.maxTokens = botJson["maxTokens"];
    bot.temperature = botJson["temperature"];
    bot.systemPrompts = botJson["systemPrompts"];
    if (json["api"] != null) bot.api = botJson["api"];
    if (json["model"] != null) bot.model = botJson["model"];

    final apisJson = json["apis"] as Map<String, Map>;
    for (final pair in apisJson.entries) {
      final api = pair.value;
      apis[pair.key] = ConfigAPI(
        url: api["url"],
        key: api["key"],
        models: api["models"],
      );
    }
  }

  static Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    json["bot"] = {
      "api": bot.api,
      "model": bot.model,
      "maxTokens": bot.maxTokens,
      "temperature": bot.temperature,
      "systemPrompts": bot.systemPrompts,
    };

    final map = {};
    json["apis"] = map;

    for (final pair in apis.entries) {
      final api = pair.value;
      map[pair.key] = {
        "url": api.url,
        "key": api.key,
        "models": api.models,
      };
    }

    return json;
  }

  static late final File _file;
  static late final String _filePath;
  static late final Directory _directory;
  static const String _fileName = "settings.json";

  static Future<void> initialize() async {
    _directory = await getApplicationDocumentsDirectory();
    _filePath = "${_directory.path}${Platform.pathSeparator}$_fileName";

    _file = File(_filePath);
    if (await _file.exists()) {
      final data = await _file.readAsString();
      fromJson(jsonDecode(data));
    } else {
      bot = ConfigBot();
      apis = {};
      save();
    }
  }

  static Future<void> save() async {
    await _file.writeAsString(jsonEncode(toJson()));
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
  ..["root"] =
      TextStyle(color: Color(0xffabb2bf), backgroundColor: Colors.transparent);

final codeLightTheme = Map.of(atomOneLightTheme)
  ..["root"] =
      TextStyle(color: Color(0xffabb2bf), backgroundColor: Colors.transparent);
