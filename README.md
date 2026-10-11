# CommNEUcate

CommNEUcate is a Flutter lost-and-found app for NEU. Students can report found items, browse reports, submit claims, and chat about item recovery. The project also includes an admin portal for approvals, disputes, and QR scanning.

## Built with

- Flutter and Dart
- Supabase Auth and database
- `image_picker`, `mobile_scanner`, and `qr_flutter`

## Getting started

1. Install the Flutter SDK and platform tooling for your target platform.
2. Clone this repository and enter the project folder.
3. Install packages with `flutter pub get`.
4. Run the app with `flutter run`.

The app currently initializes its Supabase project in `lib/main.dart`. To use a different backend, update the Supabase URL and publishable key there and configure the required authentication, database tables, and Row Level Security policies in Supabase.

## Checks

Run static analysis with:

```sh
flutter analyze
```

Run the widget tests with:

```sh
flutter test
```

## Platforms

The repository includes Flutter platform folders for Android, iOS, web, Windows, macOS, and Linux. Plugin support and required tooling can vary by platform; build and run with the corresponding Flutter target.
