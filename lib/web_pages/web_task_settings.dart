import 'package:flutter/material.dart';

class WebTaskSettingsPage extends StatefulWidget {
  const WebTaskSettingsPage({super.key});

  @override
  State<WebTaskSettingsPage> createState() => _WebTaskSettingsPageState();
}

class _WebTaskSettingsPageState extends State<WebTaskSettingsPage> {
  Map<String, bool> settings = {
    "显示任务标题": true,
    "显示负责人": true,
    "显示截止日期": true,
    "显示创建者": false,
    "显示状态标签": true,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "任务展示项设置",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.purpleAccent,
          ),
        ),
        const SizedBox(height: 20),

        _card(
          child: Column(
            children: [
              for (var entry in settings.entries)
                SwitchListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (v) {
                    setState(() {
                      settings[entry.key] = v;
                    });
                  },
                ),
              const SizedBox(height: 20),
              _button("保存设置"),
            ],
          ),
        )
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.purple.shade100,
            offset: const Offset(0, 7),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _button(String text) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.purpleAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {},
        child: Text(text),
      ),
    );
  }
}
