# Kagong Map (카공지도)

Students and remote workers finding the perfect cafe to study — with real-time crowd levels, outlet availability, and noise monitoring.

## Features

- Real-time crowd level tracking
- Power outlet availability info
- Noise level monitoring
- User reviews and ratings
- Naver Maps integration for nearby cafe discovery

## Tech Stack

- **Framework:** Flutter (Android, iOS, Web)
- **Backend:** Firebase (Firestore, Auth, Storage)
- **Maps:** Naver Maps SDK (`flutter_naver_map`)
- **State Management:** Riverpod

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Android Studio / Xcode
- Firebase project configured
- Naver Cloud Platform Client ID

### Installation

```bash
# Clone the repository
git clone https://github.com/earth9743/StudyCafe.git
cd StudyCafe

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Build

```bash
flutter build apk    # Android
flutter build ios    # iOS
flutter build web    # Web
```

## Project Structure

```
lib/
  main.dart          # App entry point
android/             # Android native configuration
ios/                 # iOS native configuration
test/                # Widget & unit tests
```
