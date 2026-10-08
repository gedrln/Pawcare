# PawCare 🐾

PawCare is a Flutter app for keeping pet profiles and care schedules together. It uses Supabase for account access and cloud data, with local notifications for schedule reminders on supported platforms.

## Features

- **User Authentication**
  - Sign up and sign in
  - Email verification
  - Password reset
  - Google sign-in
  - Logout and session management

- **Pet Management**
  - Add pet profiles
  - View registered pets
  - Edit pet information
  - Add or update pet photos
  - Store pet name, species, breed, birthdate, age, gender, and pet status
  - Add health notes and fun facts

- **Pet Scheduling**
  - Calendar-based schedule
  - Add and edit pet activities
  - Set activity type and title
  - Set date and time
  - Set recurring schedules
  - Add optional notes
  - Mark activities as complete
  - Receive local schedule reminders on supported platforms

- **Home Dashboard**
  - View the active pet
  - Quick access to My Pets
  - Quick access to Pet Schedule
  - View today's or upcoming activities

- **Profile and Settings**
  - Update profile details and profile photo
  - Configure notification preferences
  - Adjust accessibility options

## Built with

- Flutter and Dart
- Supabase Auth, Database, Storage, and Edge Functions
- `image_picker` and `image_cropper` for pet and profile photos
- `flutter_local_notifications` for reminders

## Requirements

- Flutter SDK with Dart 3.0 or later
- A configured Supabase project for authentication and app data
- Xcode for iOS development, or Android Studio/Android SDK for Android development


## Supabase Edge Function

The repository includes the `pawcare-ai` function at `supabase/functions/pawcare-ai/`. Deploy it with the Supabase CLI if you use the app's AI feature, and configure any required function secrets in the Supabase project. Database migrations are incremental and assume the base tables already exist.

## Project structure

```text
lib/
  core/       App constants and theme
  models/     Pet, schedule, and profile data models
  screens/    Authentication, home, pets, schedule, and settings UI
  services/   Supabase, photo, and notification logic
  widgets/    Shared interface components
supabase/
  functions/  Edge Functions
  migrations/ Database migration files
```
