enum MessageType { cmdSent, cmdReceived, msgSent, msgReceived }

class MessageItem {
  late String content;
  late MessageType type;

  MessageItem(this.content, this.type);
}
