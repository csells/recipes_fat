import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../data/recipe.dart';
import '../data/recipe_repository.dart';
import '../gemini_api_key.dart';
import '../views/recipe_content_view.dart';
import '../views/recipe_list_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchText = '';

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
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _SearchBox(onSearchChanged: _updateSearchText),
                  Expanded(child: RecipeListView(searchText: _searchText)),
                ],
              ),
            ),
            Expanded(
              child: LlmChatView(
                responseBuilder: (context, response) => _responseBuilder(
                  context,
                  response,
                ),
                provider: GeminiProvider(
                  model: "gemini-1.5-flash",
                  apiKey: geminiApiKey,
                  systemInstruction: '''
You are a helpful assistant that generates recipes based on the ingredients and 
instructions provided. 

My food preferences are:
- I don't like mushrooms, tomatoes or cilantro.
- I love garlic and onions.
- I avoid milk, so I always replace that with oat milk.
- I try to keep carbs low, so I always replace that with cauliflower rice.

When you generate a recipe, you should generate a JSON
object with the following structure:
{
  "title": "Recipe Title",
  "description": "Recipe Description",
  "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"],
  "instructions": ["Instruction 1", "Instruction 2", "Instruction 3"]
}

You should provide a heading before each JSON section titled with the name of
the recipe.

You should keep things casual and friendly. Feel free to mix text and JSON
output.
''',
                ),
              ),
            ),
          ],
        ),
      );

  void _updateSearchText(String text) => setState(() => _searchText = text);

  void _onAdd() => context.goNamed(
        'edit',
        pathParameters: {'recipe': RecipeRepository.newRecipeID},
      );

  static var re =
      RegExp('```json(?<recipe>.*?)```', multiLine: true, dotAll: true);

  Widget _responseBuilder(BuildContext context, String response) {
    // find all of the chunks of json that represent recipes
    final matches = re.allMatches(response);

    var end = 0;
    final children = <Widget>[];
    for (final match in matches) {
      // extract the text before the json
      if (match.start > end) {
        final text = response.substring(end, match.start);
        children.add(MarkdownBody(data: text));
      }

      // extract the json
      final json = match.namedGroup('recipe')!;
      final recipe = Recipe.fromJson(jsonDecode(json));
      children.add(RecipeContentView(recipe: recipe));

      // make sure we don't include the raw json output
      end = match.end;
    }

    // add the remaining text
    if (end < response.length) {
      children.add(MarkdownBody(data: response.substring(end)));
    }

    // return the children as rows in a column
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _SearchBox extends StatefulWidget {
  final Function(String) onSearchChanged;

  const _SearchBox({required this.onSearchChanged});

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search recipes',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
          onChanged: widget.onSearchChanged,
        ),
      );
}
