with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace the exact sequence
target = """                                           ],
                                         ),
] else ...["""

replacement = """                                           ],
                                         ),
                                       );
                                     },
                                   ),
                                 ] else ...["""

if target in code:
    code = code.replace(target, replacement, 1)
    print("SUCCESS: REPLACED EXACT TARGET")
else:
    print("WARNING: EXACT TARGET NOT FOUND, TRYING REGEX")
    import re
    code = re.sub(
        r'(\s*\]\,(?:\r?\n)\s*\)\,(?:\r?\n))\] else \.\.\.\[',
        r'\1                                       );\n                                     },\n                                   ),\n                                 ] else ...[',
        code,
        count=1
    )

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("FILE SAVED")
