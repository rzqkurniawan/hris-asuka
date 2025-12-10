# AI Agent Instructions for HRIS Asuka

## Project Overview
HRIS Asuka is a Flutter-based mobile Human Resource Information System with a focus on minimalist design and theming support.

## Key Architecture Patterns

### State Management
- Uses Provider pattern for app-wide state (`lib/providers/`)
- Theme state managed via `ThemeProvider` with persistent storage
- Example pattern in `theme_provider.dart`:
  ```dart
  final themeProvider = Provider.of<ThemeProvider>(context);
  themeProvider.toggleTheme();
  ```

### Screen Structure
- All screens follow consistent layout patterns in `lib/screens/`
- Navigation uses named routes defined in `main.dart`
- Screen flow: Splash → Login → Register
- Each screen must handle loading states and form validation

### Theming System
- Dual theme support (Light/Dark) defined in `lib/theme/app_theme.dart`
- Colors follow Midnight Ocean palette (see README for exact values)
- System UI (status/nav bars) adapts to theme automatically
- Theme changes must be persisted using `shared_preferences`

### Custom Components
- Reusable widgets stored in `lib/widgets/`
- Bottom sheets use specific animation timings (200-600ms)
- Form fields must implement validation
- Components should support both light/dark themes

## Development Workflow

### Environment Setup
Required versions:
- Flutter SDK ≥3.0.0
- Dart SDK ≥3.0.0

### Common Commands
```bash
# Install dependencies
flutter pub get

# Run app in debug mode
flutter run

# Build release APK
flutter build apk --release

# Build app bundle
flutter build appbundle --release
```

### Performance Guidelines
- Use `const` constructors when possible
- Implement `shouldRebuild` in provider classes
- Keep widget tree depth minimal
- Cache network responses

## Testing & Validation
- Unit tests location: `test/`
- Command: `flutter test --coverage`
- UI tests should verify theme compatibility

## Project Structure Conventions
```
lib/
├── models/       # Data models (PODOs)
├── providers/    # State management
├── screens/      # Full-page UI
├── theme/        # Theme configuration
└── widgets/      # Reusable components
```

## Integration Points
- Authentication (pending API implementation)
- Local storage using `shared_preferences`
- System UI theme integration
- Custom font integration (Google Fonts - Inter)

## Common Pitfalls
- Always use named routes for navigation
- Theme changes must update SystemUIOverlayStyle
- Bottom sheets require specific animation timing
- Form validation must be consistent across screens

For more details, consult the `README.md` in the project root.