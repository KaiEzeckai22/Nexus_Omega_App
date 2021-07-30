class Log {
  late final String title;
  late final String tags;
  late final List<dynamic> content;
  late String id;

  Log(this.title, this.tags, this.content);

  Log.fromJson(Map json)
      : title = json['title'],
        tags = json['tags'],
        content = json['content'],
        id = json['_id'];
  // add contact numbers

  Map toJson() {
    return {
      'title': title,
      'tags': tags,
      'content': content,
    };
  }
}
