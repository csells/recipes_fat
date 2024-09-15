import 'package:uuid/uuid.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String notes;
  final List<double>? embedding;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    this.tags = const [],
    this.notes = '',
    this.embedding,
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
        id: json['id'] ?? const Uuid().v4(),
        title: json['title'],
        description: json['description'],
        ingredients: List<String>.from(json['ingredients']),
        instructions: List<String>.from(json['instructions']),
        tags: json['tags'] == null ? [] : List<String>.from(json['tags']),
        notes: json['notes'] ?? '',
        embedding: json['embedding'] == null
            ? null
            : List<double>.from(json['embedding']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'tags': tags,
        'notes': notes,
        if (embedding != null) 'embedding': embedding,
      };

  @override
  String toString() => '''Recipe(
  id: $id,
  title: $title,
  description: $description,
  ingredients: ${ingredients.length},
  instructions: ${instructions.length},
  tags: $tags,
  notes: ${notes.isNotEmpty ? notes : 'No notes'},
  embedding: ${embedding != null ? '[${embedding![0]}, ${embedding![1]}, ${embedding![2]}, ...]' : 'No embedding'},
)''';

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    List<String>? tags,
    String? notes,
    List<double>? embedding,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      embedding: embedding ?? this.embedding,
    );
  }
}
