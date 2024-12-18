import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/edit_recipe_page.dart';
import 'pages/home_page.dart';
import 'recipe_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RecipeRepository.init();
  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, _) => const HomePage(),
        routes: [
          GoRoute(
            name: 'edit',
            path: 'edit/:recipe',
            builder: (context, state) {
              final recipeId = state.pathParameters['recipe']!;
              final recipe = RecipeRepository.getRecipe(recipeId);
              return EditRecipePage(recipe: recipe);
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.blue),
      );
}
