import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recipe_data/recipe.dart';

import 'gemini_api_key.dart';

void main(List<String> args) async {
  // await createEmbeddings();

  // check embeddings
  // final recipes = await loadRecipes('../../recipes_grandma_rag.json');
  // print(recipes.length);
  // print(recipes.first);

  // search embeddings
  await searchEmbeddings('I want to make an apple cake.');
}

Future<void> searchEmbeddings(String query) async {
  final recipes = await loadRecipes('../../recipes_grandma_rag.json');
  final model = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: geminiApiKey,
  );
  final queryEmbedding = await getQueryEmbedding(model, query);

  for (final recipe in recipes) {
    final dotProduct = computeDotProduct(recipe.embedding!, queryEmbedding);
    print('${recipe.title}: $dotProduct');
  }
}

double computeDotProduct(List<double> a, List<double> b) {
  double sum = 0.0;
  for (var i = 0; i < a.length; ++i) {
    sum += a[i] * b[i];
  }

  return sum;
}

Future<void> createEmbeddings() async {
  final recipes = await loadRecipes('../../recipes_grandma.json');
  final model = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: geminiApiKey,
  );

  final recipesWithEmbeddings = <Recipe>[];
  for (final recipe in recipes) {
    final embedding = await getDocumentEmbedding(model, recipe);
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
