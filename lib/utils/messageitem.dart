import 'package:geolocator/geolocator.dart';

enum MessageType { cmdSent, cmdReceived, msgSent, msgReceived }

class MessageItem {
  late String content;
  late MessageType type;
  late DateTime time;
  late Position position;

  MessageItem(String originalContent, this.type, this.time) {
    content = originalContent.trim();
  }

  MessageItem.withPosition(
      String originalContent, this.type, this.time, this.position) {
    content = originalContent.trim();
  }
}
