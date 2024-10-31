import "../config.dart";

import "package:flutter/material.dart";
import "package:markdown/markdown.dart" as md;
import "package:markdown/markdown.dart" hide Element;
import "package:flutter_markdown/flutter_markdown.dart";
import "package:flutter_highlighter/flutter_highlighter.dart";
import "package:flutter_markdown_latex/flutter_markdown_latex.dart";

class Message {
  String text;
  String? image;
  MessageRole role;

  Message({required this.role, required this.text, this.image});
}

enum MessageRole {
  assistant,
  user,
}

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  static final extensionSet = ExtensionSet(
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

  @override
  Widget build(BuildContext context) {
    String content = message.text;
    final Alignment alignment;
    final Color background;

    final colorScheme = Theme.of(context).colorScheme;
    final markdownStyleSheet = MarkdownStyleSheet(
      codeblockDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainer,
      ),
    );

    if (message.image != null) {
      content = "![image](${message.image})\n\n${message.text}";
    }

    switch (message.role) {
      case MessageRole.user:
        background = colorScheme.secondaryContainer;
        alignment = Alignment.centerRight;
        break;

      case MessageRole.assistant:
        background = colorScheme.surfaceContainerHighest;
        alignment = Alignment.centerLeft;
        break;
    }

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: background, borderRadius: BorderRadius.circular(8)),
              child: MarkdownBody(
                data: content,
                shrinkWrap: true,
                selectable: true,
                extensionSet: extensionSet,
                builders: {
                  "code": CodeElementBuilder(context: context),
                  "latex": LatexElementBuilder(textScaleFactor: 1.2),
                },
                styleSheet: markdownStyleSheet,
                styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
              ),
            ),
          );
        },
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeElementBuilder({required this.context});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final theme = switch (Theme.of(context).colorScheme.brightness) {
      Brightness.light => codeblockLightTheme,
      Brightness.dark => codeblockDarkTheme,
    };
    var language = "";

    if (element.attributes["class"] != null) {
      language = element.attributes["class"]!.substring(9);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: HighlightView(
        tabSize: 2,
        theme: theme,
        language: language,
        element.textContent.trim(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}
