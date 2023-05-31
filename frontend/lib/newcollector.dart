import 'package:flutter/material.dart';
import 'remote.dart';
import 'main.dart';

class NewCollectorPage extends StatefulWidget {
  const NewCollectorPage({super.key});

  @override
  State<NewCollectorPage> createState() => _NewCollectorPageState();
}

class _NewCollectorPageState extends State<NewCollectorPage> {
  final nameCon = TextEditingController();
  final promCon = TextEditingController();
  final expCon = TextEditingController(text: '7');
  final numCon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(
          flex: 3,
        ),
        TextField(
            controller: nameCon, decoration: generateInputStyle("收集任务名称")),
        const Spacer(),
        TextField(
          controller: promCon,
          decoration: generateInputStyle("收集文件标识信息"),
        ),
        const Padding(
            padding: EdgeInsets.all(8), child: Text('用于提示用户输入的个人信息, 例如：姓名-电话')),
        const Spacer(),
        Row(children: [
          Expanded(
              flex: 3,
              child: TextField(
                  controller: numCon, decoration: generateInputStyle('目标数量'))),
          const Spacer(),
          Expanded(
              flex: 3,
              child: TextField(
                  controller: expCon,
                  decoration: generateInputStyle('收集期限（天）')))
        ]),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: draft,
          icon: const Icon(
            Icons.create_new_folder_outlined,
            size: iconSize,
          ),
          label: const Text(
            '发布新收集',
            style: bigfont,
          ),
          style: elevateButtonStyle,
        ),
        const Spacer(
          flex: 3,
        ),
      ],
    );
  }

  void draft() {
    final s = ScaffoldMessenger.of(context);
    if (nameCon.text.isEmpty ||
        promCon.text.isEmpty ||
        int.tryParse(numCon.text) == null ||
        int.tryParse(expCon.text) == null) {
      showError(s, '输入有误，请检查输入！');
    } else {
      registerNewCollector(nameCon.text, promCon.text, int.parse(numCon.text),
              int.parse(expCon.text))
          .then((value) {
        if (value[0]) {
          Navigator.of(context)
              .pushNamed(afterRegisterNewCol, arguments: value);
        } else {
          showError(s, '服务器内部错误，请重试！');
        }
      });
    }
  }
}
