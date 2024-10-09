import 'package:geolocator/geolocator.dart';

enum MessageType { cmdSent, cmdReceived, msgSent, msgReceived }

class MessageItem {
  late String content;
  late MessageType type;
  late DateTime time;
  late Position? position = null;

  MessageItem(String originalContent, this.type, this.time) {
    content = originalContent.trim();
  }

  MessageItem.withPosition(String originalContent, this.type, this.time,
      Future<Position> futurePosition) {
    content = originalContent.trim();
    futurePosition.then((v) {
      position = v;
    });
  }

  String getPosition() {
    return "${position?.latitude.toString()},${position?.longitude.toString()}";
  }
}
