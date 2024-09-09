class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String notes;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.tags = const [],
    this.notes = '',
  });

  Recipe.empty(String id)
      : this(
          id: id,
          title: '',
          description: '',
          ingredients: [],
          instructions: [],
          tags: [],
          notes: '',
        );

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        ingredients: List<String>.from(json['ingredients']),
        instructions: List<String>.from(json['instructions']),
        tags: List<String>.from(json['tags']),
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'tags': tags,
        'notes': notes,
      };

  @override
  String toString() => 'Recipe('
      'id: $id, '
      'title: $title, '
      'description: $description, '
      'ingredients: ${ingredients.length}, '
      'instructions: ${instructions.length}, '
      'tags: $tags, '
      'notes: ${notes.isNotEmpty ? notes : 'No notes'}'
      ')';
}
