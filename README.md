# Aanchal Boutique — Booking App

Developed the foundation of Aanchal Boutique’s booking app using Flutter and clean feature-first architecture.

## Architecture

Feature-first structure, Riverpod for state, SQLite (`sqflite`) for storage:

```
lib/
├── main.dart                   # Opens the database, then starts the app
├── app.dart                    # MaterialApp + theme
├── core/
│   ├── constants/              # User-facing strings
│   ├── database/               # AppDatabase (schema + seed), databaseProvider
│   ├── theme/                  # Colors and ThemeData
│   └── utils/                  # clockProvider, date/time formatters (intl)
└── features/
    ├── shell/                  # Bottom navigation (Home / Staff)
    ├── staff/                  # Daily schedule for the boutique owner
    ├── home/
    │   ├── domain/             # Room model, RoomRepository interface
    │   ├── data/               # SqliteRoomRepository, room status sync
    │   └── presentation/       # roomsProvider, HomeScreen, RoomCard
    └── booking/
        ├── domain/             # Booking model, BookingRules, BookingRepository
        ├── data/               # SqliteBookingRepository
        └── presentation/       # bookingsProvider, BookingScreen, BookingsScreen
```

### Data

- **rooms**: `id`, `name`, `status` (`available` / `busy` / `booked`), `sort_order`
- **bookings**: `id`, `room_id`, `date`, `start_time`, `customer_name`,
  `status` (`confirmed` / `cancelled`), `created_at`, `cancelled_at`

A unique index allows only one *confirmed* booking per room and slot, so
double-booking is rejected by the database itself. Cancelling deletes the
booking. A room is `booked` while it has a confirmed booking that hasn't ended;
this is re-checked on every start, booking and cancellation.

The database lives on the device, so uninstalling the app erases it. Backup or
server sync would be needed for that.

## Run

```bash
flutter pub get
flutter run
flutter test
```
