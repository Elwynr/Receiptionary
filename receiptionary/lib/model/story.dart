class StoryOwner {
  final String owner;
  final String profileImage;
  final List<Story> stories;

  StoryOwner({
    required this.owner,
    required this.profileImage,
    required this.stories,
  });

  factory StoryOwner.fromJson(Map<String, dynamic> json) {
    var storyList = json['posts'] as List;
    List<Story> stories = storyList.map((i) => Story.fromJson(i)).toList();

    return StoryOwner(
      owner: json['market'],
      profileImage: json['profile_image'],
      stories: stories,
    );
  }
}

class Story {
  final int date;
  final String text;
  final String image;

  Story({
    required this.date,
    required this.text,
    required this.image,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      date: json['date'],
      text: json['text'],
      image: json['image'],
    );
  }
}
