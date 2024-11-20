// from https://ai.google.dev/gemini-api/tutorials/document_search
import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recipe_data/recipe_data.dart';

import 'gemini_api_key.dart';

const filenameRecipes = '../../recipes_grandma.json';
const filenameEmbeddings = '../../embeddings_grandma.json';

final embeddingsModel = GenerativeModel(
  model: 'text-embedding-004',
  apiKey: geminiApiKey,
);

void main(List<String> args) async {
  // await createEmbeddings();

  // // check embeddings
  // final recipes = await loadRecipes(filenameRecipes);
  // final embeddings = await loadEmbeddings(filenameEmbeddings);
  // print('${recipes.length} recipes');
  // print('${embeddings.length} embeddings');
  // print('first recipe: ${recipes.first}');
  // print(embeddings.first.embedding.length); // should both be 768
  // print(embeddings.last.embedding.length);

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
  final recipes = await loadRecipes(filenameRecipes);
  final embeddings = await loadEmbeddings(filenameEmbeddings);
  final queryEmbedding = await getQueryEmbedding(query);

  final scoredRecipes = <({Recipe recipe, double score})>[];
  for (final recipe in recipes) {
    final recipeEmbedding = embeddings.singleWhere((e) => e.id == recipe.id);
    final dotProduct = GeminiEmbeddingHelper.computeDotProduct(
      queryEmbedding,
      recipeEmbedding.embedding,
    );
    // print('${recipe.title}: $dotProduct');
    scoredRecipes.add((recipe: recipe, score: dotProduct));
  }

  return scoredRecipes.sortedByDescending((r) => r.score).take(numResults);
}

Future<void> createEmbeddings() async {
  final recipes = await loadRecipes(filenameRecipes);
  final embeddings = <RecipeEmbedding>[];
  for (final recipe in recipes) {
    final embedding = await getDocumentEmbedding(recipe);
    final recipeEmbedding = RecipeEmbedding(
      id: recipe.id,
      embedding: embedding,
    );
    embeddings.add(recipeEmbedding);
    print('${embeddings.length} / ${recipes.length}');
  }

  await saveEmbeddings(filenameEmbeddings, embeddings);
}

Future<List<Recipe>> loadRecipes(String filename) async {
  final json = await File(filename).readAsString();
  final jsonList = jsonDecode(json) as List;
  return [for (final json in jsonList) Recipe.fromJson(json)];
}

Future<void> saveEmbeddings(
  String filename,
  List<RecipeEmbedding> embeddings,
) async {
  final jsonString = jsonEncode(embeddings.map((e) => e.toJson()).toList());
  await File(filename).writeAsString(jsonString);
}

Future<List<RecipeEmbedding>> loadEmbeddings(String filename) async {
  final json = await File(filename).readAsString();
  final jsonList = jsonDecode(json) as List;
  return [for (final json in jsonList) RecipeEmbedding.fromJson(json)];
}

Future<List<double>> getDocumentEmbedding(Recipe recipe) async {
  final md = recipeToMarkdown(recipe);
  final content = Content.text(md);
  final result = await embeddingsModel.embedContent(
    content,
    taskType: TaskType.retrievalDocument,
  );

  return result.embedding.values;
}

Future<List<double>> getQueryEmbedding(String query) async {
  final content = Content.text(query);
  final result = await embeddingsModel.embedContent(
    content,
    taskType: TaskType.retrievalQuery,
  );

  return result.embedding.values;
}

String recipeToMarkdown(Recipe recipe) => '''
# ${recipe.title}
${recipe.description}

## Ingredients
${recipe.ingredients.join('\n')}

## Instructions
${recipe.instructions.join('\n')}
''';
