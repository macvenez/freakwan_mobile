enum MessageType { cmdSent, cmdReceived, msgSent, msgReceived }

class MessageItem {
  late String content;
  late MessageType type;
  late DateTime time;

  MessageItem(String originalContent, this.type, this.time) {
    content = originalContent.trim();
  }
}
