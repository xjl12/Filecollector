import 'package:file_exchange/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'remote.dart';
import 'homepage.dart';

class QueryCollector extends StatefulWidget {
  final int? sharekey;
  final String? passwd;
  const QueryCollector({super.key, this.sharekey, this.passwd});

  @override
  State<QueryCollector> createState() => _QueryCollectorState();
}

class _QueryCollectorState extends State<QueryCollector> {
  int? sharekey;
  int all = 1, received = 0;
  bool isPasswdOK = false, hasrequest = false;
  String? name, passwd;
  @override
  Widget build(BuildContext context) {
    if (sharekey == null) {
      final data = ModalRoute.of(context)?.settings.arguments as List?;
      if (data == null) {
        if (widget.passwd != null && widget.sharekey != null) {
          sharekey = widget.sharekey;
          passwd = widget.passwd;
          name = '错误';
          queryCollectorStatus(sharekey!, passwd!).then(_afterquery);
        } else {
          return Container();
        }
      } else {
        sharekey = data[0];
        name = data[1];
      }
    }
    return Column(
      children: [
        const Spacer(
          flex: 3,
        ),
        showCollectName(name),
        const Spacer(),
        TextFormField(
          decoration: const InputDecoration(
              label: Text("请输入查询密码"), border: OutlineInputBorder()),
          autovalidateMode: isPasswdOK
              ? AutovalidateMode.disabled
              : AutovalidateMode.onUserInteraction,
          readOnly: isPasswdOK,
          validator: (text) {
            if (text == null || text.length != 4) {
              hasrequest = false;
              return "密码长度不足";
            }
            if (hasrequest && !isPasswdOK) {
              hasrequest = false;
              return "查询密码不正确";
            }
            passwd = text;
            queryCollectorStatus(sharekey!, text).then(_afterquery);
            return null;
          },
        ),
        const Spacer(),
        Opacity(
          opacity: isPasswdOK ? 1 : 0,
          child: Stack(alignment: AlignmentDirectional.center, children: [
            LinearProgressIndicator(
              value: received / all,
              minHeight: 50,
            ),
            Text(
              "进度：已收到$received份 / 共$all份",
              style: bigfont,
            ),
          ]),
        ),
        const Spacer(),
        OutlinedButton.icon(
            onPressed: isPasswdOK ? delete : null,
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 60)),
            icon: const Icon(
              Icons.delete_outline,
              size: iconSize,
            ),
            label: const Text(
              "删除收集任务",
              style: bigfont,
            )),
        const Spacer(),
        ElevatedButton.icon(
            onPressed: isPasswdOK && received > 0 ? download : null,
            icon: const Icon(
              Icons.download,
              size: iconSize,
            ),
            style: elevateButtonStyle,
            label: const Text(
              "下载收集文件包",
              style: bigfont,
            )),
        const Spacer(
          flex: 3,
        ),
      ],
    );
  }

  void _afterquery(value) {
    setState(() {
      hasrequest = true;
      if (value[0]) {
        isPasswdOK = true;
        received = value[1];
        all = value[2];
        name = value[3];
      }
    });
  }

  void downloadCallback(value) {
    if (!value) {
      showError(ScaffoldMessenger.of(context), '下载错误，请重试！');
    }
  }

  void download() {
    if (kIsWeb) {
      downloadCollectorFile(sharekey!, passwd!, null).then(downloadCallback);
    } else {
      String filename = '${name}_收集结果.zip';
      getSavePath(suggestedName: filename).then((value) {
        if (value != null) {
          downloadCollectorFile(sharekey!, passwd!, '$value$filename')
              .then(downloadCallback);
        }
      });
    }
  }

  void delete() {
    deleteCollector(sharekey!, passwd!).then((value) {
      if (value) {
        Navigator.of(context)
            .pushNamed(successRouteName, arguments: "该收集任务删除成功");
      } else {
        showError(ScaffoldMessenger.of(context), '收集任务删除失败！');
      }
    });
  }
}
