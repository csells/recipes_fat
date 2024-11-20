// NOTE: 240826: Now sorting recipe list by title

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_data/recipe_data.dart';

import '../recipe_repository.dart';
import 'recipe_view.dart';

class RecipeListView extends StatefulWidget {
  const RecipeListView({required this.searchText, super.key});
  final String searchText;

  @override
  _RecipeListViewState createState() => _RecipeListViewState();
}

class _RecipeListViewState extends State<RecipeListView> {
  final _expanded = <String, bool>{};

  // NEW: RB: 240826: Sort by Title:
  Iterable<Recipe> _filteredRecipes(Iterable<Recipe> recipes) => recipes
      .where((recipe) =>
          recipe.title
              .toLowerCase()
              .contains(widget.searchText.toLowerCase()) ||
          recipe.description
              .toLowerCase()
              .contains(widget.searchText.toLowerCase()) ||
          recipe.tags.any((tag) =>
              tag.toLowerCase().contains(widget.searchText.toLowerCase())))
      .toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Iterable<Recipe>?>(
        valueListenable: RecipeRepository.items,
        builder: (context, recipes, child) {
          if (recipes == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final displayedRecipes = _filteredRecipes(recipes).toList();
          return ListView.builder(
            itemCount: displayedRecipes.length,
            itemBuilder: (context, index) {
              final recipe = displayedRecipes[index];
              final recipeId = recipe.id;
              return RecipeView(
                key: ValueKey(recipeId),
                recipe: recipe,
                expanded: _expanded[recipeId] ?? false,
                onExpansionChanged: (expanded) =>
                    _onExpand(recipe.id, expanded),
                onEdit: () => _onEdit(recipe),
                onDelete: () => unawaited(_onDelete(recipe)),
              );
            },
          );
        },
      );

  void _onExpand(String recipeId, bool expanded) =>
      _expanded[recipeId] = expanded;

  void _onEdit(Recipe recipe) => context.goNamed(
        'edit',
        pathParameters: {'recipe': recipe.id},
      );

  Future<void> _onDelete(Recipe recipe) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text(
          'Are you sure you want to delete the recipe "${recipe.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) await RecipeRepository.deleteRecipe(recipe);
  }
}
