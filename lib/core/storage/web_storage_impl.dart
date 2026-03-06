import 'package:web/web.dart';

String? readWebStorage(String key) => window.localStorage.getItem(key);
void writeWebStorage(String key, String value) {
  window.localStorage.setItem(key, value);
}
void deleteWebStorage(String key) {
  window.localStorage.removeItem(key);
}
