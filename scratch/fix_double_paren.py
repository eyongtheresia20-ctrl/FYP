with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the exact double closing parenthesis
old_str = """                                                  }).toList(),
                                                ),
                                               ),
                                              ],"""

new_str = """                                                  }).toList(),
                                                ),
                                              ],"""

if old_str in text:
    text = text.replace(old_str, new_str, 1)
    print("SUCCESS: REPLACED EXACT DOUBLE CLOSING PARENTHESIS")
else:
    # Try normalized
    text = text.replace(
        "}).toList(),\n                                                ),\n                                               ),\n                                              ],",
        "}).toList(),\n                                                ),\n                                              ],"
    )
    print("NORMALIZED REPLACEMENT APPLIED")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)
