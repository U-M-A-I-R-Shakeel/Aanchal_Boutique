# Aanchal Boutique — Booking App

Developed the foundation of Aanchal Boutique’s booking app using Flutter and clean feature-first architecture.

## Architecture

Feature-first structure with Riverpod for state management:

```
lib/
├── main.dart                 # Entry point, wraps app in ProviderScope
├── app.dart                  # MaterialApp + theme
├── core/
│   ├── constants/            # App-wide strings
│   └── theme/                # Colors and ThemeData
└── features/
    └── home/
        ├── data/             # RoomRepository (static data for now)
        ├── domain/models/    # Room model + RoomStatus enum
        └── presentation/
            ├── providers/    # roomsProvider (Riverpod Notifier)
            ├── screens/      # HomeScreen
            └── widgets/      # RoomCard, StatusBadge
```

## Run

```bash
flutter pub get
flutter run
flutter test
```
