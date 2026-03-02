import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/tokens/Colors.tokens.json');

  if (!file.existsSync()) {
    print("❌ Token file not found.");
    return;
  }

  final jsonData = jsonDecode(await file.readAsString());

  final buffer = StringBuffer();

  buffer.writeln("// ⚠️ AUTO-GENERATED FILE. DO NOT EDIT.");
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln('');
  buffer.writeln('class AppColors {');
  buffer.writeln('  AppColors._();');
  buffer.writeln('');

  extractColors(jsonData, buffer);

  buffer.writeln('}');

  final output = File('lib/src/app_colors.dart');
  await output.create(recursive: true);
  await output.writeAsString(buffer.toString());

  print("✅ Colors generated successfully!");
}

/// Recursively search for color tokens
void extractColors(
    Map<String, dynamic> map,
    StringBuffer buffer, [
      String parentKey = '',
    ]) {
  map.forEach((key, value) {
    final formattedKey = formatKey(parentKey, key);

    if (value is Map<String, dynamic>) {
      /// Detect Figma color token
      if (value.containsKey(r'$type') &&
          value[r'$type'] == 'color' &&
          value.containsKey(r'$value')) {

        final colorValue = value[r'$value'];

        if (colorValue is Map<String, dynamic> &&
            colorValue.containsKey('hex')) {

          final hex = colorValue['hex']
              .toString()
              .replaceAll('#', '');

          buffer.writeln(
              '  static const Color $formattedKey = Color(0xFF$hex);');
        }
      } else {
        extractColors(value, buffer, formattedKey);
      }
    }
  });
}

/// Format nested keys into valid Dart variable name
String formatKey(String parent, String current) {
  final combined = parent.isEmpty ? current : '${parent}_$current';

  return combined
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
      .replaceAllMapped(
      RegExp(r'_(\w)'), (m) => m.group(1)!.toUpperCase())
      .replaceAllMapped(
      RegExp(r'^(\d)'), (m) => '_${m.group(1)}')
      .toLowerCase();
}