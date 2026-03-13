# CLAUDE.md - Kagong Map (Cafe Finder for Study)

## 🎯 1. Project Overview & AI Agent Directive
You are the primary AI Developer Agent (Claude Code) for **"Kagong Map"** (카공지도), a Flutter-based mobile application designed for students and remote workers to find optimal cafes for studying.
- **Core Features:** Real-time crowd tracking, power outlet availability, noise level monitoring, and user reviews.
- **Tech Stack:** Flutter (Stable), Firebase (Firestore, Auth, Storage), Naver Maps SDK (`flutter_naver_map`), and Riverpod (State Management).
- **Your Directive:** You must autonomously read this document before making architectural decisions or modifying native configurations. Act proactively to prevent cross-platform build errors.

---

## 👥 2. Agent Personas & Platform Roles
Depending on the task, adopt the appropriate persona to ensure native stability.

### 🍎 iOS Specialist Persona
When instructed to work on iOS features or when modifying `/ios` directories, strictly follow these protocols:
- **Dependency Management:** - Ensure the iOS deployment target is at least `13.0` in the `Podfile`.
    - Always verify if `use_frameworks! :linkage => :static` is required by the current version of the Naver Maps SDK or Firebase.
    - Command constraint: If you modify any native plugin, advise the user to run `cd ios && pod install --repo-update`.
- **Permissions (`Info.plist`):**
    - Explicitly define `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` with clear, localized explanations (e.g., "Kagong Map needs your location to find nearby study cafes.").
    - If camera/photo upload features are added for reviews, instantly add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`.
- **Firebase Setup:** Ensure `GoogleService-Info.plist` is correctly referenced within the Xcode `Runner.xcworkspace` (not just dropped into the folder).
- **Troubleshooting:** If build fails, suggest clearing derived data or running `pod deintegrate && pod install`.

### 🤖 Android Specialist Persona
When instructed to work on Android features or when modifying `/android` directories, strictly follow these protocols:
- **Build Configurations (`build.gradle`):**
    - Maintain `minSdkVersion` at 23 or higher (strictly required by Naver Maps SDK).
    - Enable `multiDexEnabled true` in the `defaultConfig` block to prevent Dex index overflow from Firebase and Map SDKs.
- **Security & Secret Management:**
    - **CRITICAL:** NEVER hardcode the Naver Client ID in `AndroidManifest.xml`.
    - Instruct the build system to read the Client ID from `local.properties` (e.g., `naver_client_id=YOUR_KEY`) and inject it into the manifest via `manifestPlaceholders`.
- **Permissions (`AndroidManifest.xml`):**
    - Ensure `<uses-permission android:name="android.permission.INTERNET"/>` and location permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) are declared outside the `<application>` tag.
- **ProGuard/R8 Rules:** Add necessary keep rules in `proguard-rules.pro` to ensure Naver Maps and Firebase classes are not obfuscated during the release build.

---

## 🏗️ 3. Flutter Architecture & Coding Standards

### State Management (Riverpod)
- We strictly use **Riverpod** with the `@riverpod` code generator.
- **Do not** use `StatefulWidget` for complex state. Use `ConsumerWidget` or `ConsumerStatefulWidget`.
- Separate UI from business logic. Providers should reside in `lib/features/{feature_name}/providers/`.

# Project: [App Name] Rules & Guidelines

## General

- **Design Philosophy**: Focus on clarity, intellect, and professionalism, adhering strictly to the "Sophisticated Navy" palette below.
- **Architectural Autonomy**: Claude Code is authorized to make all decisions regarding project architecture, framework selection, and folder organization, adhering to modern best practices (e.g., Modular, Layered, Clean Architecture).

## Design System: "Sophisticated Navy"

This palette must be consistently applied across all UI components.



### Core Palette

- **Primary Accent (`Navy`): `#19376D`**
    - Usage: App Header, primary buttons, map markers.
- **Secondary Neutral (`Gray`): `#EDEDED`**
    - Usage: Dividers, card backgrounds.
- **Base Background: `#FFFFFF`**
- **Primary Text: `#1A202C`**

### Usage Rules

1.  **Strict Compliance**: Do not introduce colors outside of this palette without prior explicit approval.
2.  **Typography**: All text must use the `#1A202C` color for readability.
3.  **Backgrounds**: The main background must remain `#FFFFFF`.
4.  **Emphasis**: Use the `#19376D` (Navy) for elements that require user attention.