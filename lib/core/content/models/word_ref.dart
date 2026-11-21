/// The vocabulary word attached to an alphabet letter, used as the
/// FR -> EN vocabulary bridge described in CLAUDE.md section 8.
class WordRef {
  const WordRef({required this.label, required this.image, required this.audio});

  final String label;
  final String image;
  final String audio;

  factory WordRef.fromJson(Map<String, dynamic> json) {
    return WordRef(
      label: json['label'] as String,
      image: json['image'] as String,
      audio: json['audio'] as String,
    );
  }
}
