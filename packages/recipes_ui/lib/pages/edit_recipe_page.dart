// NOTE: RB: 240826: Switched to a form for editing recipes. Added text hints
// and validation for required fields.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_data/recipe_data.dart';
import 'package:uuid/uuid.dart';

import '../recipe_repository.dart';

class EditRecipePage extends StatefulWidget {
  const EditRecipePage({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.recipe.title,
    );
    _descriptionController = TextEditingController(
      text: widget.recipe.description,
    );
    _ingredientsController = TextEditingController(
      text: widget.recipe.ingredients.join('\n'),
    );
    _instructionsController = TextEditingController(
      text: widget.recipe.instructions.join('\n'),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  bool get _isNewRecipe => widget.recipe.id == RecipeRepository.newRecipeID;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${_isNewRecipe ? "Add" : "Edit"} Recipe')),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter a name for your recipe...',
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Recipe title is requires'
                      : null,
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'In a few words, describe your recipe...',
                  ),
                  maxLines: null,
                ),
                TextField(
                  controller: _ingredientsController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients (one per line)',
                    hintText: 'e.g., 2 cups flour\n1 tsp salt\n1 cup sugar',
                  ),
                  maxLines: null,
                ),
                TextField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (one per line)',
                    hintText: 'e.g., Mix ingredients\nBake for 30 minutes',
                  ),
                  maxLines: null,
                ),
                const Gap(16),
                OutlinedButton(
                  onPressed: _onDone,
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );

  void _onDone() {
    if (!_formKey.currentState!.validate()) return;

    final recipe = Recipe(
      id: _isNewRecipe ? const Uuid().v4() : widget.recipe.id,
      title: _titleController.text,
      description: _descriptionController.text,
      ingredients: _ingredientsController.text.split('\n'),
      instructions: _instructionsController.text.split('\n'),
    );

    if (_isNewRecipe) {
      RecipeRepository.addNewRecipe(recipe);
    } else {
      RecipeRepository.updateRecipe(recipe);
    }

    if (context.mounted) context.goNamed('home');
  }
}
