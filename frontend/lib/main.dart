import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'homepage.dart';
import 'query.dart';
import 'remote.dart';
import 'newcollector.dart';

const String appTitle = '文件收集客户端',
    homeRouteName = '/home',
    queryCollectorState = '/queryCollectorState',
    successRouteName = '/success',
    draftNewCollector = '/draftNewCollector',
    afterRegisterNewCol = '/afterRegisterNewCol';
var navData = {
  homeRouteName: () => const FileCollectorMain(),
  queryCollectorState: () => const QueryCollector(),
  successRouteName: () => const SuccessPage(),
  draftNewCollector: () => const NewCollectorPage(),
  afterRegisterNewCol: () => const PrintCollectorInfo()
};
const TextStyle bigfont = TextStyle(fontSize: 18);
const double iconSize = 23;
final elevateButtonStyle =
    ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60));
final outlineButStyle =
    OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 60));

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      color: Colors.blue.shade600,
      initialRoute: '/home',
      onGenerateRoute: (RouteSettings settings) {
        String name = settings.name ?? '/home';
        var url = Uri.parse(name);
        var contentBuilder = navData[url.path] ?? navData[homeRouteName]!;
        Widget? content;
        if (url.queryParameters.containsKey('key')) {
          int? sharekey = int.tryParse(url.queryParameters['key']!);
          if (sharekey != null && url.path == homeRouteName) {
            content = FileCollectorMain(sharekey: sharekey);
          }
        } else if (url.queryParameters.containsKey('password') &&
            url.path == queryCollectorState) {
          content = QueryCollector(
              passwd: url.queryParameters['password'],
              sharekey: int.tryParse(url.queryParameters['sharekey']!));
        }
        content ??= contentBuilder();
        return MyPageTransition(BackgroundWidget(content), settings);
      },
    );
  }

  Widget getPageContent(String path, Map arg) {
    switch (path) {
      default:
        return const FileCollectorMain();
    }
  }
}

class BackgroundWidget extends StatelessWidget {
  final Widget content;
  const BackgroundWidget(this.content, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(alignment: Alignment.center, children: [
      Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.cover, image: AssetImage('img/background.jpg'))),
      ),
      LayoutBuilder(builder: ((p0, BoxConstraints p1) {
        double cons = min(p1.maxHeight, p1.maxWidth);
        double width = min(cons, 500);
        return Container(
            width: width,
            height: width / 0.8,
            padding: const EdgeInsets.all(30),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                    child: Container(
                      color: Colors.white.withOpacity(0.618),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: 30, horizontal: width / 10),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 12,
                          color: Colors.black.withOpacity(0.618),
                          blurStyle: BlurStyle.outer)
                    ],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(children: [
                    Expanded(child: content),
                    Row(
                      children: [
                        const Spacer(),
                        const Text(
                          "Powered by",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Image.asset(
                          "img/openeuler.png",
                          height: 25,
                        ),
                        const Spacer(),
                        Image.asset(
                          "img/opengauss.png",
                          height: 25,
                        ),
                        const Spacer()
                      ],
                    )
                  ]),
                ),
              ],
            ));
      }))
    ]));
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    String msg =
        ModalRoute.of(context)?.settings.arguments as String? ?? '操作成功';
    return Column(
      children: [
        const Spacer(
          flex: 3,
        ),
        const Icon(
          Icons.check,
          color: Color.fromARGB(255, 36, 142, 60),
          size: 100,
        ),
        const Spacer(),
        Text(msg,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        const Spacer(
          flex: 3,
        )
      ],
    );
  }
}

class PrintCollectorInfo extends StatelessWidget {
  const PrintCollectorInfo({super.key});
  static const big = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    var data = ModalRoute.of(context)?.settings.arguments as List?;
    String sharekey = data?[1] ?? '错误';
    String passwd = data?[2] ?? '错误';
    return Column(
      children: [
        const Spacer(flex: 3),
        const Icon(
          Icons.check,
          size: 80,
          color: Color.fromARGB(255, 36, 142, 60),
        ),
        const Spacer(),
        const Text(
          "收集任务发布成功，请将文件收集码或提交链接分发给用户，并保存好查询密码或查询链接",
          style: bigfont,
        ),
        const Spacer(),
        Expanded(
            flex: 5,
            child: SelectionArea(
                child: Column(children: [
              Row(children: [
                Text(
                  '收  集  码：$sharekey',
                  style: big,
                ),
                const Spacer(),
                linkButton('$serverURL#$homeRouteName?key=$sharekey', context)
              ]),
              const Spacer(),
              Row(
                children: [
                  Text(
                    '查询密码：$passwd',
                    style: big,
                  ),
                  const Spacer(),
                  linkButton(
                      '$serverURL#$queryCollectorState?sharekey=$sharekey&password=$passwd',
                      context)
                ],
              )
            ]))),
        const Spacer(flex: 3),
      ],
    );
  }
}

class MyPageTransition extends PageRouteBuilder {
  final Widget widget;
  MyPageTransition(this.widget, args)
      : super(
            settings: args,
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (p1, p2, p3) => widget,
            transitionsBuilder: (p1, p2, p3, p4) {
              return FadeTransition(
                opacity: Tween(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: p2, curve: Curves.fastOutSlowIn)),
                child: p4,
              );
            });
}

void showError(ScaffoldMessengerState s, String txt) {
  s.showSnackBar(SnackBar(
      content: Text(txt),
      behavior: SnackBarBehavior.floating,
      action:
          SnackBarAction(label: "确定", onPressed: (() => s.clearSnackBars()))));
}

Widget linkButton(String link, BuildContext context) {
  return IconButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: link));
        showError(ScaffoldMessenger.of(context), '链接地址已复制');
      },
      tooltip: "复制链接地址",
      icon: const Icon(
        Icons.link,
        size: iconSize + 10,
      ));
}

InputDecoration generateInputStyle(String label) {
  return InputDecoration(border: const OutlineInputBorder(), labelText: label);
}
