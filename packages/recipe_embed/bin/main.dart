// from https://ai.google.dev/gemini-api/tutorials/document_search
import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recipe_data/recipe_data.dart';

import 'gemini_api_key.dart';

void main(List<String> args) async {
  // await createEmbeddings();

  // check embeddings
  // final recipes = await loadRecipes('../../recipes_grandma_rag.json');
  // print('${recipes.length} recipes');
  // print('first recipe: ${recipes.first}');
  // print(recipes.first.embedding!.length); // should both be 768
  // print(recipes.last.embedding!.length);

  // search embeddings
  final scoredRecipes = await searchEmbeddings(
    'I want to make an apple cake.',
    numResults: 3,
  );

  print(
    scoredRecipes.map((sr) => '${sr.recipe.title}: ${sr.score}').join('\n'),
  );
}

Future<Iterable<({Recipe recipe, double score})>> searchEmbeddings(
  String query, {
  int numResults = 1,
}) async {
  final recipes = await loadRecipes('../../recipes_grandma_rag.json');
  final model = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: geminiApiKey,
  );
  final embeddings = await loadEmbeddings('../../recipes_grandma_rag.json');
  final queryEmbedding = await getQueryEmbedding(model, query);

  final scoredRecipes = <({Recipe recipe, double score})>[];
  for (final recipe in recipes) {
    final recipeEmbedding = embeddings.singleWhere((e) => e.id == recipe.id);
    final score = computeDotProduct(queryEmbedding, recipeEmbedding.embedding);
    // print('${recipe.title}: $score');
    scoredRecipes.add((recipe: recipe, score: score));
  }

  return scoredRecipes.sortedByDescending((r) => r.score).take(numResults);
}

double computeDotProduct(List<double> a, List<double> b) {
  double sum = 0.0;
  for (var i = 0; i < a.length; ++i) {
    sum += a[i] * b[i];
  }

  return sum;
}

// todo: replace with createEmbeddings that creates a separate file
// Future<void> createEmbeddings() async {
//   final recipes = await loadRecipes('../../recipes_grandma.json');
//   final model = GenerativeModel(
//     model: 'text-embedding-004',
//     apiKey: geminiApiKey,
//   );

//   final recipesWithEmbeddings = <Recipe>[];
//   for (final recipe in recipes) {
//     final embedding = await getDocumentEmbedding(model, recipe);
//     final recipeWithEmbedding = recipe.copyWith(embedding: embedding);
//     recipesWithEmbeddings.add(recipeWithEmbedding);
//     print('${recipesWithEmbeddings.length} / ${recipes.length}');
//   }

//   await saveRecipes('../../recipes_grandma_rag.json', recipesWithEmbeddings);
// }

Future<List<Recipe>> loadRecipes(String filename) async {
  final json = await File(filename).readAsString();
  final jsonList = jsonDecode(json) as List;
  return [for (final json in jsonList) Recipe.fromJson(json)];
}

Future<void> saveRecipes(String filename, List<Recipe> recipes) async {
  final jsonString = jsonEncode(recipes.map((r) => r.toJson()).toList());
  await File(filename).writeAsString(jsonString);
}

Future<List<RecipeEmbedding>> loadEmbeddings(String filename) async {
  final json = await File(filename).readAsString();
  final jsonList = jsonDecode(json) as List;
  return [for (final json in jsonList) RecipeEmbedding.fromJson(json)];
}

Future<List<double>> getDocumentEmbedding(
  GenerativeModel model,
  Recipe recipe,
) async {
  final md = _recipeToMarkdown(recipe);
  final content = Content.text(md);
  final result = await model.embedContent(
    content,
    taskType: TaskType.retrievalDocument,
  );

  return result.embedding.values;
}

Future<List<double>> getQueryEmbedding(
  GenerativeModel model,
  String query,
) async {
  final content = Content.text(query);
  final result = await model.embedContent(
    content,
    taskType: TaskType.retrievalQuery,
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
