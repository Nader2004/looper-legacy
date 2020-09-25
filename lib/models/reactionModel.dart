class Reactions {
  final double happy;
  final double sad;
  final double surprised;
  final double angry;
  final double fear;
  final double disgust;
  final double contempt;
  final double neutral;
  const Reactions({
    this.happy,
    this.sad,
    this.surprised,
    this.angry,
    this.fear,
    this.disgust,
    this.contempt,
    this.neutral,
  });

  factory Reactions.fromJson(Map<String, dynamic> emotion) {
    return Reactions(
      happy: emotion['happiness'],
      sad: emotion['sadness'],
      surprised: emotion['surprise'],
      angry: emotion['anger'],
      disgust: emotion['disgust'],
      fear: emotion['fear'],
      contempt: emotion['contempt'],
      neutral: emotion['neutral'],
    );
  }
}
