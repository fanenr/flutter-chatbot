// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `ChatBot`
  String get title {
    return Intl.message(
      'ChatBot',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get ok {
    return Intl.message(
      'Ok',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get copy {
    return Intl.message(
      'Copy',
      name: 'copy',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get play {
    return Intl.message(
      'Play',
      name: 'play',
      desc: '',
      args: [],
    );
  }

  /// `Source`
  String get source {
    return Intl.message(
      'Source',
      name: 'source',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Camera`
  String get camera {
    return Intl.message(
      'Camera',
      name: 'camera',
      desc: '',
      args: [],
    );
  }

  /// `Gallery`
  String get gallery {
    return Intl.message(
      'Gallery',
      name: 'gallery',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Bot`
  String get bot {
    return Intl.message(
      'Bot',
      name: 'bot',
      desc: '',
      args: [],
    );
  }

  /// `Bots`
  String get bots {
    return Intl.message(
      'Bots',
      name: 'bots',
      desc: '',
      args: [],
    );
  }

  /// `APIs`
  String get apis {
    return Intl.message(
      'APIs',
      name: 'apis',
      desc: '',
      args: [],
    );
  }

  /// `Config`
  String get config {
    return Intl.message(
      'Config',
      name: 'config',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get open {
    return Intl.message(
      'Open',
      name: 'open',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message(
      'Reset',
      name: 'reset',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get error {
    return Intl.message(
      'Error',
      name: 'error',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Reanswer`
  String get reanswer {
    return Intl.message(
      'Reanswer',
      name: 'reanswer',
      desc: '',
      args: [],
    );
  }

  /// `API`
  String get api {
    return Intl.message(
      'API',
      name: 'api',
      desc: '',
      args: [],
    );
  }

  /// `Model`
  String get model {
    return Intl.message(
      'Model',
      name: 'model',
      desc: '',
      args: [],
    );
  }

  /// `Voice`
  String get voice {
    return Intl.message(
      'Voice',
      name: 'voice',
      desc: '',
      args: [],
    );
  }

  /// `Max Tokens`
  String get max_tokens {
    return Intl.message(
      'Max Tokens',
      name: 'max_tokens',
      desc: '',
      args: [],
    );
  }

  /// `Temperature`
  String get temperature {
    return Intl.message(
      'Temperature',
      name: 'temperature',
      desc: '',
      args: [],
    );
  }

  /// `System Prompts`
  String get system_prompts {
    return Intl.message(
      'System Prompts',
      name: 'system_prompts',
      desc: '',
      args: [],
    );
  }

  /// `Streaming Response`
  String get streaming_response {
    return Intl.message(
      'Streaming Response',
      name: 'streaming_response',
      desc: '',
      args: [],
    );
  }

  /// `Link`
  String get link {
    return Intl.message(
      'Link',
      name: 'link',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `New Bot`
  String get new_bot {
    return Intl.message(
      'New Bot',
      name: 'new_bot',
      desc: '',
      args: [],
    );
  }

  /// `New API`
  String get new_api {
    return Intl.message(
      'New API',
      name: 'new_api',
      desc: '',
      args: [],
    );
  }

  /// `New Chat`
  String get new_chat {
    return Intl.message(
      'New Chat',
      name: 'new_chat',
      desc: '',
      args: [],
    );
  }

  /// `API Url`
  String get api_url {
    return Intl.message(
      'API Url',
      name: 'api_url',
      desc: '',
      args: [],
    );
  }

  /// `API Key`
  String get api_key {
    return Intl.message(
      'API Key',
      name: 'api_key',
      desc: '',
      args: [],
    );
  }

  /// `Model List`
  String get model_list {
    return Intl.message(
      'Model List',
      name: 'model_list',
      desc: '',
      args: [],
    );
  }

  /// `Select Models`
  String get select_models {
    return Intl.message(
      'Select Models',
      name: 'select_models',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a name`
  String get enter_a_name {
    return Intl.message(
      'Please enter a name',
      name: 'enter_a_name',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a title`
  String get enter_a_title {
    return Intl.message(
      'Please enter a title',
      name: 'enter_a_title',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate Bot name`
  String get duplicate_bot_name {
    return Intl.message(
      'Duplicate Bot name',
      name: 'duplicate_bot_name',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate API name`
  String get duplicate_api_name {
    return Intl.message(
      'Duplicate API name',
      name: 'duplicate_api_name',
      desc: '',
      args: [],
    );
  }

  /// `Please complete all fields`
  String get complete_all_fields {
    return Intl.message(
      'Please complete all fields',
      name: 'complete_all_fields',
      desc: '',
      args: [],
    );
  }

  /// `no model`
  String get no_model {
    return Intl.message(
      'no model',
      name: 'no_model',
      desc: '',
      args: [],
    );
  }

  /// `All Chats`
  String get all_chats {
    return Intl.message(
      'All Chats',
      name: 'all_chats',
      desc: '',
      args: [],
    );
  }

  /// `Chat Title`
  String get chat_title {
    return Intl.message(
      'Chat Title',
      name: 'chat_title',
      desc: '',
      args: [],
    );
  }

  /// `Default Config`
  String get default_config {
    return Intl.message(
      'Default Config',
      name: 'default_config',
      desc: '',
      args: [],
    );
  }

  /// `Text To Speech`
  String get text_to_speech {
    return Intl.message(
      'Text To Speech',
      name: 'text_to_speech',
      desc: '',
      args: [],
    );
  }

  /// `Chat Image Compress`
  String get chat_image_compress {
    return Intl.message(
      'Chat Image Compress',
      name: 'chat_image_compress',
      desc: '',
      args: [],
    );
  }

  /// `Config Import and Export`
  String get config_import_export {
    return Intl.message(
      'Config Import and Export',
      name: 'config_import_export',
      desc: '',
      args: [],
    );
  }

  /// `Choose Bot`
  String get choose_bot {
    return Intl.message(
      'Choose Bot',
      name: 'choose_bot',
      desc: '',
      args: [],
    );
  }

  /// `Choose API`
  String get choose_api {
    return Intl.message(
      'Choose API',
      name: 'choose_api',
      desc: '',
      args: [],
    );
  }

  /// `Choose Model`
  String get choose_model {
    return Intl.message(
      'Choose Model',
      name: 'choose_model',
      desc: '',
      args: [],
    );
  }

  /// `Quality`
  String get quality {
    return Intl.message(
      'Quality',
      name: 'quality',
      desc: '',
      args: [],
    );
  }

  /// `Minimal Width`
  String get min_width {
    return Intl.message(
      'Minimal Width',
      name: 'min_width',
      desc: '',
      args: [],
    );
  }

  /// `Minimal Height`
  String get min_height {
    return Intl.message(
      'Minimal Height',
      name: 'min_height',
      desc: '',
      args: [],
    );
  }

  /// `Export Config`
  String get export_config {
    return Intl.message(
      'Export Config',
      name: 'export_config',
      desc: '',
      args: [],
    );
  }

  /// `Import Config`
  String get import_config {
    return Intl.message(
      'Import Config',
      name: 'import_config',
      desc: '',
      args: [],
    );
  }

  /// `Empty`
  String get empty {
    return Intl.message(
      'Empty',
      name: 'empty',
      desc: '',
      args: [],
    );
  }

  /// `Enable`
  String get enable {
    return Intl.message(
      'Enable',
      name: 'enable',
      desc: '',
      args: [],
    );
  }

  /// `Please Input`
  String get please_input {
    return Intl.message(
      'Please Input',
      name: 'please_input',
      desc: '',
      args: [],
    );
  }

  /// `The original image will be used if compression fails.`
  String get image_enable_hint {
    return Intl.message(
      'The original image will be used if compression fails.',
      name: 'image_enable_hint',
      desc: '',
      args: [],
    );
  }

  /// `The quality setting should be between 1 and 100, with lower values resulting in higher compression. Minimum width and minimum height restrict image resizing. Leave these fields blank if you're unsure.`
  String get image_hint {
    return Intl.message(
      'The quality setting should be between 1 and 100, with lower values resulting in higher compression. Minimum width and minimum height restrict image resizing. Leave these fields blank if you\'re unsure.',
      name: 'image_hint',
      desc: '',
      args: [],
    );
  }

  /// `To avoid export failures, it's recommended to export the configuration to the Documents directory, or create a ChatBot subdirectory within your Downloads folder.`
  String get config_hint {
    return Intl.message(
      'To avoid export failures, it\'s recommended to export the configuration to the Documents directory, or create a ChatBot subdirectory within your Downloads folder.',
      name: 'config_hint',
      desc: '',
      args: [],
    );
  }

  /// `Exported Successfully`
  String get exported_successfully {
    return Intl.message(
      'Exported Successfully',
      name: 'exported_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Imported Successfully`
  String get imported_successfully {
    return Intl.message(
      'Imported Successfully',
      name: 'imported_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Please restart App to load the new settings.`
  String get restart_app {
    return Intl.message(
      'Please restart App to load the new settings.',
      name: 'restart_app',
      desc: '',
      args: [],
    );
  }

  /// `Can't write to that directory.`
  String get failed_to_export {
    return Intl.message(
      'Can\'t write to that directory.',
      name: 'failed_to_export',
      desc: '',
      args: [],
    );
  }

  /// `Clone Chat`
  String get clone_chat {
    return Intl.message(
      'Clone Chat',
      name: 'clone_chat',
      desc: '',
      args: [],
    );
  }

  /// `Clear Chat`
  String get clear_chat {
    return Intl.message(
      'Clear Chat',
      name: 'clear_chat',
      desc: '',
      args: [],
    );
  }

  /// `Chat Settings`
  String get chat_settings {
    return Intl.message(
      'Chat Settings',
      name: 'chat_settings',
      desc: '',
      args: [],
    );
  }

  /// `Cloned Successfully`
  String get cloned_successfully {
    return Intl.message(
      'Cloned Successfully',
      name: 'cloned_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to clear the chat?`
  String get ensure_clear_chat {
    return Intl.message(
      'Are you sure you want to clear the chat?',
      name: 'ensure_clear_chat',
      desc: '',
      args: [],
    );
  }

  /// `Saved Successfully`
  String get saved_successfully {
    return Intl.message(
      'Saved Successfully',
      name: 'saved_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Copied Successfully`
  String get copied_successfully {
    return Intl.message(
      'Copied Successfully',
      name: 'copied_successfully',
      desc: '',
      args: [],
    );
  }

  /// `Not implemented yet`
  String get not_implemented_yet {
    return Intl.message(
      'Not implemented yet',
      name: 'not_implemented_yet',
      desc: '',
      args: [],
    );
  }

  /// `Empty Link`
  String get empty_link {
    return Intl.message(
      'Empty Link',
      name: 'empty_link',
      desc: '',
      args: [],
    );
  }

  /// `Cannot Open`
  String get cannot_open {
    return Intl.message(
      'Cannot Open',
      name: 'cannot_open',
      desc: '',
      args: [],
    );
  }

  /// `Invalid Max Tokens`
  String get invalid_max_tokens {
    return Intl.message(
      'Invalid Max Tokens',
      name: 'invalid_max_tokens',
      desc: '',
      args: [],
    );
  }

  /// `Invalid Temperature`
  String get invalid_temperature {
    return Intl.message(
      'Invalid Temperature',
      name: 'invalid_temperature',
      desc: '',
      args: [],
    );
  }

  /// `Enter your message`
  String get enter_your_message {
    return Intl.message(
      'Enter your message',
      name: 'enter_your_message',
      desc: '',
      args: [],
    );
  }

  /// `Failed to comprese image`
  String get image_compress_failed {
    return Intl.message(
      'Failed to comprese image',
      name: 'image_compress_failed',
      desc: '',
      args: [],
    );
  }

  /// `Set up the TTS first`
  String get setup_tts_first {
    return Intl.message(
      'Set up the TTS first',
      name: 'setup_tts_first',
      desc: '',
      args: [],
    );
  }

  /// `Set up the Bot and API first`
  String get setup_bot_api_first {
    return Intl.message(
      'Set up the Bot and API first',
      name: 'setup_bot_api_first',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
