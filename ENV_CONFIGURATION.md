# Environment Configuration with .env Files

This project uses `.env` files to manage environment-specific configurations like API URLs, making it easy to switch between development, staging, and production environments.

## Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Create Your .env File

Copy the example file and customize it:

```bash
cp .env.example .env
```

Or manually create `.env` in the project root:

```env
# Backend API URL
API_BASE_URL=http://localhost:3000
```

### 3. Run the App

```bash
flutter run
```

## Configuration Priority

The app uses the following priority order for determining the API base URL:

1. **User-configured URL** (via app settings in Profile page)
2. **`.env` file** variable
3. **Hardcoded default** (`http://localhost:3000`)

## Environment Files

### `.env`
Your local configuration (gitignored, never commit this!)

```env
API_BASE_URL=http://localhost:3000
```

### `.env.example`
Template file that should be committed to git

```env
API_BASE_URL=http://localhost:3000
```

### `.env.local`
Alternative local configuration (also gitignored)

## Common Configurations

### Local Development
```env
API_BASE_URL=http://localhost:3000
```

### Local Network Testing (iOS/Android device)
```env
# Replace with your computer's IP address
API_BASE_URL=http://192.168.1.100:3000
```

### Staging Environment
```env
API_BASE_URL=https://staging-api.zdatar.com
```

### Production Environment
```env
API_BASE_URL=https://api.zdatar.com
```

## Usage in Code

The `.env` file is automatically loaded when the app starts:

```dart
// main.dart
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

Access environment variables:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

String apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
```

## Changing API URL at Runtime

Users can also change the API URL from within the app:

1. Open the app
2. Navigate to **Profile** page
3. Tap **"API Configuration"**
4. Enter a custom URL or use preset buttons
5. Tap **"Save"**

This setting is saved to device storage and takes precedence over the `.env` file.

## Best Practices

### ✅ DO:
- Keep `.env.example` updated with all required variables (without sensitive values)
- Document each environment variable with comments
- Use descriptive variable names
- Commit `.env.example` to git
- Create separate `.env` files for different team members

### ❌ DON'T:
- Commit `.env` files with actual secrets or API keys
- Hardcode URLs or secrets directly in code
- Share your `.env` file with others
- Use production URLs in development

## Adding New Environment Variables

1. Add the variable to `.env.example`:
```env
# My new variable
MY_NEW_VAR=default_value
```

2. Add to your actual `.env`:
```env
MY_NEW_VAR=actual_value
```

3. Use in code:
```dart
String myValue = dotenv.env['MY_NEW_VAR'] ?? 'fallback';
```

## Troubleshooting

### Problem: "Unable to load asset: .env"

**Solution:** Make sure `.env` is listed in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - .env
```

### Problem: Environment variables are null

**Solution:** 
1. Ensure `.env` file exists in project root
2. Run `flutter clean` and `flutter pub get`
3. Restart the app

### Problem: Changes to .env not reflected

**Solution:**
1. Hot restart won't reload `.env` - do a full restart
2. Run `flutter clean`
3. Stop and restart the app

## Team Setup

When a new team member joins:

1. Clone the repository
2. Copy `.env.example` to `.env`
3. Ask team lead for appropriate values
4. Run `flutter pub get`
5. Run the app

## CI/CD Integration

For continuous integration and deployment, you can:

1. **Use build arguments:**
```bash
flutter build apk --dart-define=API_BASE_URL=https://api.zdatar.com
```

2. **Set environment variables in CI:**
```yaml
# GitHub Actions example
- name: Create .env file
  run: echo "API_BASE_URL=${{ secrets.API_URL }}" > .env
```

3. **Use different .env files:**
```bash
# Development
cp .env.dev .env
flutter build apk

# Production
cp .env.prod .env
flutter build apk --release
```

## Security Notes

- ⚠️ **Never commit sensitive data** like API keys, passwords, or tokens to git
- The `.env` file is added to `.gitignore` by default
- Only commit `.env.example` with placeholder values
- For production secrets, use secure secret management services
- Consider encrypting sensitive `.env` files if needed

## Package Documentation

This project uses [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) package.

For more details, see: https://pub.dev/packages/flutter_dotenv
