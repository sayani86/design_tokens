import json
import os
import re

def format_key(parent, current):
    combined = current if not parent else f"{parent}_{current}"
    # Remove non-alphanumeric
    combined = re.sub(r'[^a-zA-Z0-9_]', '', combined)
    # camelCase: _x -> X
    combined = re.sub(r'_(\w)', lambda m: m.group(1).upper() if m.group(1) else '', combined)
    # Prefix if starts with digit
    if re.match(r'^\d', combined):
        combined = f"_{combined}"
    return combined.lower()

def extract_colors(data, parent_key=''):
    colors = []
    # Sort keys to ensure deterministic output
    for key in sorted(data.keys()):
        value = data[key]
        formatted_key = format_key(parent_key, key)
        if isinstance(value, dict):
            # Detect Figma color token
            if value.get('$type') == 'color' and '$value' in value:
                color_val = value['$value']
                if isinstance(color_val, dict) and 'hex' in color_val:
                    hex_val = color_val['hex'].replace('#', '')
                    colors.append(f"  static const Color {formatted_key} = Color(0xFF{hex_val.upper()});")
            else:
                colors.extend(extract_colors(value, formatted_key))
    return colors

def main():
    token_path = 'assets/tokens/Colors.tokens.json'
    if not os.path.exists(token_path):
        print(f"❌ Token file not found: {token_path}")
        return

    try:
        with open(token_path, 'r') as f:
            json_data = json.load(f)

        colors = extract_colors(json_data)

        output_content = [
            "// ⚠️ AUTO-GENERATED FILE. DO NOT EDIT.",
            "import 'package:flutter/material.dart';",
            "",
            "class AppColors {",
            "  AppColors._();",
            ""
        ]
        output_content.extend(colors)
        output_content.append("}")

        output_path = 'lib/src/app_colors.dart'
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, 'w') as f:
            f.write('\n'.join(output_content) + '\n')

        print("✅ Colors generated successfully!")
    except Exception as e:
        print(f"❌ Error generating colors: {e}")

if __name__ == "__main__":
    main()
