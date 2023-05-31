import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'remote.dart';
import 'main.dart';

class FileCollectorMain extends StatefulWidget {
  final int? sharekey;
  const FileCollectorMain({super.key, this.sharekey});

  @override
  State<FileCollectorMain> createState() => _FileCollectorMainState();
}

class _FileCollectorMainState extends State<FileCollectorMain> {
  bool correct = false, lastCheck = false, filenameOK = false;
  String? prompt, name;
  int? sharekey;
  final TextEditingController filenameEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (widget.sharekey != null) {
      sharekey = widget.sharekey;
      queryCollectorKey(sharekey!).then(_afterquery);
    }
    return Column(
      children: [
        const Spacer(
          flex: 3,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: correct ? showCollectName(name) : sharekeyInputBox(),
        ),
        const Spacer(),
        Visibility(
          visible: correct,
          child: TextFormField(
            controller: filenameEditingController,
            decoration: generateInputStyle(prompt ?? '错误'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: filenameValidator,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          label: const Text(
            '文件上传',
            style: bigfont,
          ),
          icon: const Icon(
            Icons.upload_file,
            size: iconSize,
          ),
          onPressed: correct && filenameOK
              ? () => openFile().then((value) {
                    if (value != null) {
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (con) {
                            uploadFile(value, filenameEditingController.text,
                                    sharekey!)
                                .then(
                              (value) {
                                Navigator.pop(con);
                                if (value) {
                                  Navigator.of(context).pushNamed(
                                      successRouteName,
                                      arguments: '文件上传成功');
                                } else {
                                  showError(ScaffoldMessenger.of(context),
                                      "文件上传失败！请重试");
                                }
                              },
                            );
                            return AlertDialog(
                                title: Row(
                              children: const [
                                Spacer(),
                                CircularProgressIndicator.adaptive(),
                                Spacer(),
                                Text("正在上传文件"),
                                Spacer()
                              ],
                            ));
                          });
                    }
                  })
              : null,
          style: outlineButStyle,
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: correct
              ? () => Navigator.of(context)
                  .pushNamed(queryCollectorState, arguments: [sharekey, name])
              : null,
          icon: const Icon(
            Icons.search,
            size: iconSize,
          ),
          label: const Text(
            '查询文件收集进度',
            style: bigfont,
          ),
          style: outlineButStyle,
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(draftNewCollector),
          icon: const Icon(
            Icons.add_circle_outline,
            size: iconSize,
          ),
          label: const Text(
            "创建新文件收集",
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

  String? filenameValidator(value) {
    String? res;
    if (value == null || value.isEmpty) res = "该字段不能为空";
    if (!value.contains(RegExp(r'^[^\/:*?""<>|]+$'))) {
      res = "出现非法字符";
    }
    Timer(
        const Duration(milliseconds: 100),
        () => setState(
              () => filenameOK = res == null,
            ));
    return res;
  }

  Widget sharekeyInputBox() {
    return TextFormField(
        maxLength: 6,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
            border: OutlineInputBorder(), labelText: "请输入文件收集码"),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (text) {
          const errorstr = '收集码不存在';
          const invalid = "出现非数字字符";
          if (text == null || text.length != 6) {
            lastCheck = false;
            return null;
          } else if (int.tryParse(text) == null) {
            lastCheck = false;
            return invalid;
          } else if (lastCheck && !correct) {
            return errorstr;
          } else {
            sharekey = int.parse(text);
            queryCollectorKey(int.parse(text)).then(_afterquery);
          }
          return null;
        });
  }

  void _afterquery(value) {
    lastCheck = true;
    if (value[0]) {
      setState(() {
        correct = true;
        name = value[1];
        prompt = value[2];
      });
    } else {
      setState(() => correct = false);
    }
  }
}

Widget showCollectName(String? name) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 37),
    child: Text(
      name!,
      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
    ),
  );
}
