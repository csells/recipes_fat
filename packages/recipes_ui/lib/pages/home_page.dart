import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recipe_data/recipe_data.dart';

import '../gemini_api_key.dart';
import '../recipe_repository.dart';
import '../views/recipe_list_view.dart';
import '../views/recipe_response_view.dart';
import '../views/search_box.dart';
import '../views/split_or_tabs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _searchText = '';

  final embeddingModel = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: geminiApiKey,
  );

  final _provider = GeminiProvider(
    model: GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiApiKey,
      systemInstruction: Content.system(
        '''
You are a helpful assistant that generates recipes based on the ingredients and
instructions provided.

My food preferences are:
- I don't like mushrooms, tomatoes or cilantro.
- I love garlic and onions.
- I avoid milk, so I always replace that with oat milk.
- I try to keep carbs low, so I try to use appropriate substitutions.

When you generate a recipe, you should generate a JSON object with the following
structure:
{
  "title": "Recipe Title",
  "description": "Recipe Description",
  "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
  "instructions": ["Instruction 1", "Instruction 2", "Instruction 3"]
}

You should keep things casual and friendly. Feel free to mix rich text and JSON
output.
''',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Recipes'),
          actions: [
            IconButton(
              onPressed: _onAdd,
              tooltip: 'Add Recipe',
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: SplitOrTabs(
          tabs: const [
            Tab(text: 'Recipes'),
            Tab(text: 'Chat'),
          ],
          children: [
            Column(
              children: [
                SearchBox(onSearchChanged: _updateSearchText),
                Expanded(child: RecipeListView(searchText: _searchText)),
              ],
            ),
            LlmChatView(
              provider: _provider,
              responseBuilder: (context, response) =>
                  RecipeResponseView(response),
              messageSender: _messageSender,
            ),
          ],
        ),
      );

  void _updateSearchText(String text) => setState(() => _searchText = text);

  void _onAdd() => context.goNamed(
        'edit',
        pathParameters: {'recipe': RecipeRepository.newRecipeID},
      );

  Stream<String> _messageSender(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    final buffer = StringBuffer();
    VoidCallback? fixup;
    if (prompt.toLowerCase().contains('grandma')) {
      final recipe = await _searchEmbeddings(prompt);
      buffer.writeln("# Grandma's Recipe:");
      buffer.write(recipe.toString());
      buffer.writeln();

      fixup = () {
        // replace the last user message with the prompt that the user actually
        // entered, not the fixed up prompt we're sending to the LLM
        final history = _provider.history.toList();
        final lastUserMessage = history.lastWhere(
          (m) => m.origin == MessageOrigin.user,
        );
        lastUserMessage.text = prompt;
      };
    }
    buffer.write(prompt);

    final response = _provider.sendMessageStream(
      buffer.toString(),
      attachments: attachments,
    );

    await for (final message in response) {
      // apply any fixups to the message history after the LLM has responded so
      // we know that the history has been updated
      if (fixup != null) {
        await Future.microtask(fixup);
        fixup = null;
      }

      yield message;
    }
  }

  List<Recipe>? _grandmasRecipes;
  List<RecipeEmbedding>? _grandmasEmbeddings;

  Future<Recipe?> _searchEmbeddings(String prompt) async {
    if (_grandmasRecipes == null) {
      assert(_grandmasEmbeddings == null);
      final json1 = await File('../../recipes_grandma.json').readAsString();
      _grandmasRecipes = await Recipe.loadFrom(json1);

      final json2 = await File('../../embeddings_grandma.json').readAsString();
      _grandmasEmbeddings = await RecipeEmbedding.loadFrom(json2);
    }

    final embeddingHelper = GeminiEmbeddingHelper(embeddingModel);
    final queryEmbedding = await embeddingHelper.getQueryEmbedding(prompt);
    Recipe? topRecipe;
    var topScore = 0.0;
    for (final recipe in _grandmasRecipes!) {
      final embedding = _grandmasEmbeddings!.singleWhere(
        (e) => e.id == recipe.id,
      );

      final score = GeminiEmbeddingHelper.computeDotProduct(
        queryEmbedding,
        embedding.embedding,
      );

      if (score > topScore) {
        topScore = score;
        topRecipe = recipe;
      }
    }

    return topRecipe;
  }
}
