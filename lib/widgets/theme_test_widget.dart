import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A test widget to verify theme persistence works on both mobile and web
/// You can add this to any screen temporarily to test theme saving/loading
class ThemeTestWidget extends StatelessWidget {
  const ThemeTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Theme Test (${kIsWeb ? "Web" : "Mobile"})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Current Theme: ${themeProvider.isDarkMode ? "Dark" : "Light"}',
            ),
            Text('Initialized: ${themeProvider.isInitialized}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => themeProvider.toggleTheme(),
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  label: const Text('Toggle Theme'),
                ),
                ElevatedButton.icon(
                  onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
                  icon: const Icon(Icons.light_mode),
                  label: const Text('Set Light'),
                ),
                ElevatedButton.icon(
                  onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
                  icon: const Icon(Icons.dark_mode),
                  label: const Text('Set Dark'),
                ),
                if (kDebugMode)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await themeProvider.clearThemePreference();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Theme preference cleared! Restart app to test.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear Saved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:\n'
              '1. Toggle or set a theme\n'
              '2. Close and reopen the app\n'
              '3. Verify the theme is preserved',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
