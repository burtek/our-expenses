# Our Expenses

A Flutter mobile application for tracking and settling shared expenses

## Features

- **Trips**: Create isolated trips with name, description, and currency (EUR/PLN/USD/GBP/CZK)
- **Participants**: Add and manage people in each trip
- **Expenses**: Track expenses with multiple payers and beneficiaries
  - Equal split, share-based split, or exact amounts
- **Settlement Groups**: Group participants for simplified settlement
- **Settlement Calculation**: Automatic balance calculation and transaction minimization
- **Localization**: English and Polish

## Architecture

```
lib/
  domain/       # Pure Dart business logic
    models/     # Immutable domain entities
    repositories/  # Abstract interfaces
    services/   # Settlement calculation engine
  data/         # Persistence layer
    database/   # SQLite database helper
    repositories/  # Concrete repository implementations
  presentation/ # UI layer
    providers/  # Riverpod state management
    screens/    # Screen widgets
    widgets/    # Reusable widget components
    l10n/       # Localization (ARB files)
```

## Key Design Decisions

- **Integer arithmetic for money**: All amounts stored as minor units (cents/grosze) to avoid floating-point errors
- **Settlement minimization**: Greedy algorithm matching largest debtors with largest creditors
- **Clean separation**: Domain layer has no Flutter dependencies
- **SQLite persistence**: Using sqflite for local storage behind repository abstraction

## Getting Started

```bash
flutter pub get
flutter run
```

## Running Tests

```bash
flutter test
```

## Building

```bash
flutter build apk --release
```

## CI/CD

GitHub Actions workflow runs on every push/PR:
1. Format check
2. Static analysis
3. Unit tests
4. Android APK build (uploaded as artifact on main)
