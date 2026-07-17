import re

with open("lib/pages/primary_page.dart", "r") as f:
    content = f.read()

# Add import
content = content.replace("import 'package:xuan_four_zhu_card/xuan_four_zhu_card.dart';", "import 'package:xuan_four_zhu_card/xuan_four_zhu_card.dart';\nimport '../l10n/generated/app_localizations.dart';")

content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;")

content = content.replace("const Text('奇门遁甲')", "Text(l10n.qimendunjia)")
content = content.replace('const Text("先天")', 'Text(l10n.xianTian)')
content = content.replace('const Text("后天")', 'Text(l10n.houTian)')
content = content.replace('Text("甲子")', 'Text(l10n.jiaZi)')

with open("lib/pages/primary_page.dart", "w") as f:
    f.write(content)
