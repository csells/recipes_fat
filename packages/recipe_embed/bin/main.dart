import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recipe_data/recipe.dart';

import 'gemini_api_key.dart';

void main(List<String> args) async {
  // await createEmbeddings();
  final recipes = await loadRecipes('../../recipes_grandma_rag.json');
  print(recipes.length);
  print(recipes.first);
}

Future<void> createEmbeddings() async {
  final recipes = await loadRecipes('../../recipes_grandma.json');
  final model = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: geminiApiKey,
  );

  final recipesWithEmbeddings = <Recipe>[];
  for (final recipe in recipes) {
    final embedding = await getEmbedding(model, recipe);
    final recipeWithEmbedding = recipe.copyWith(embedding: embedding);
    recipesWithEmbeddings.add(recipeWithEmbedding);
    print('${recipesWithEmbeddings.length} / ${recipes.length}');
  }

  await saveRecipes('../../recipes_grandma_rag.json', recipesWithEmbeddings);
}

Future<List<Recipe>> loadRecipes(String filename) async {
  final file = File(filename);
  final contents = await file.readAsString();
  final jsonList = json.decode(contents) as List;
  return [for (final json in jsonList) Recipe.fromJson(json)];
}

Future<void> saveRecipes(String filename, List<Recipe> recipes) async {
  final file = File(filename);
  final jsonString = json.encode(recipes.map((r) => r.toJson()).toList());
  await file.writeAsString(jsonString);
}

Future<List<double>> getEmbedding(GenerativeModel model, Recipe recipe) async {
  final md = _recipeToMarkdown(recipe);
  final content = Content.text(md);
  final result = await model.embedContent(
    content,
    taskType: TaskType.retrievalDocument,
  );

  return result.embedding.values;
}

String _recipeToMarkdown(Recipe recipe) => '''
# ${recipe.title}
${recipe.description}

## Ingredients
${recipe.ingredients.join('\n')}

## Instructions
${recipe.instructions.join('\n')}
''';
