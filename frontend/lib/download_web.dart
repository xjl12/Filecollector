import 'dart:html';

bool downloadCollectorFileImp(int sharekey, String passwd, String? loc, arg) {
  final anchor = document.createElement('a') as AnchorElement
    ..href = '/api/downloadCollectorFiles?sharekey=$sharekey&password=$passwd'
    ..style.display = 'none';
  document.body!.children.add(anchor);
  anchor.click();
  return true;
}
