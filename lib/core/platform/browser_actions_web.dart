import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('document')
external JSObject get _document;

JSObject get _body => _document.getProperty<JSObject>('body'.toJS);

JSObject _element(String tag) =>
    _document.callMethod<JSObject>('createElement'.toJS, tag.toJS);

const bool supported = true;

void download(String filename, String mimeType, String content) {
  final link = _element('a')
    ..setProperty(
      'href'.toJS,
      'data:$mimeType;charset=utf-8,${Uri.encodeComponent(content)}'.toJS,
    )
    ..setProperty('download'.toJS, filename.toJS);
  _body.callMethod<JSAny?>('appendChild'.toJS, link);
  link.callMethod<JSAny?>('click'.toJS);
  link.callMethod<JSAny?>('remove'.toJS);
}

/// Prints [html] from a hidden frame, so the page itself (a canvas) is not
/// what gets printed.
void printHtml(String html) {
  final frame = _element('iframe');
  frame.getProperty<JSObject>('style'.toJS)
    ..setProperty('position'.toJS, 'fixed'.toJS)
    ..setProperty('width'.toJS, '0'.toJS)
    ..setProperty('height'.toJS, '0'.toJS)
    ..setProperty('border'.toJS, '0'.toJS);
  frame.setProperty(
    'onload'.toJS,
    ((JSAny? _) {
      final window = frame.getProperty<JSObject>('contentWindow'.toJS);
      window
        ..callMethod<JSAny?>('focus'.toJS)
        ..callMethod<JSAny?>('print'.toJS);
      // Removing the frame right away can cancel the dialog in some
      // browsers; it is removed with the next print instead.
    }).toJS,
  );
  _removeOldFrames();
  frame.setProperty('className'.toJS, _frameClass.toJS);
  frame.setProperty('srcdoc'.toJS, html.toJS);
  _body.callMethod<JSAny?>('appendChild'.toJS, frame);
}

const _frameClass = 'manara-print-frame';

void _removeOldFrames() {
  final old = _document.callMethod<JSObject>(
    'getElementsByClassName'.toJS,
    _frameClass.toJS,
  );
  final count = old.getProperty<JSNumber>('length'.toJS).toDartInt;
  for (var i = count - 1; i >= 0; i--) {
    old
        .callMethod<JSObject>('item'.toJS, i.toJS)
        .callMethod<JSAny?>('remove'.toJS);
  }
}

@JS('Notification')
external JSFunction? get _notification;

String notificationPermission() {
  final notification = _notification;
  if (notification == null) return 'unsupported';
  return (notification as JSObject)
      .getProperty<JSString>('permission'.toJS)
      .toDart;
}

Future<String> requestNotificationPermission() async {
  final notification = _notification;
  if (notification == null) return 'unsupported';
  final result = await (notification as JSObject)
      .callMethod<JSPromise<JSString>>('requestPermission'.toJS)
      .toDart;
  return result.toDart;
}

void notify(String title, String body) {
  final notification = _notification;
  if (notification == null || notificationPermission() != 'granted') return;
  final options = JSObject()
    ..setProperty('body'.toJS, body.toJS)
    ..setProperty('lang'.toJS, 'ar'.toJS)
    ..setProperty('dir'.toJS, 'rtl'.toJS);
  notification.callAsConstructor<JSObject>(title.toJS, options);
}
