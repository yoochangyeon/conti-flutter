// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? readWebStorage(String key) => html.window.localStorage[key];
void writeWebStorage(String key, String value) {
  html.window.localStorage[key] = value;
}
void deleteWebStorage(String key) {
  html.window.localStorage.remove(key);
}
