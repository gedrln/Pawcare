# PawCare 🐾

PawCare is a mobile application designed to help pet owners manage their pets' information and care schedules in one place. It provides pet profile management, scheduling, authentication, and a simple dashboard for accessing important pet information.

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
  - Store pet name, species, breed, birthdate, age, and gender

- **Pet Scheduling**
  - Calendar-based schedule
  - Add pet activities
  - Set activity type and title
  - Set date and time
  - Set recurring schedules
  - Add optional notes

- **Home Dashboard**
  - View the active pet
  - Quick access to My Pets
  - Quick access to Pet Schedule
  - View today's or upcoming activities

## Technology Stack

- **Flutter** — Mobile application framework
- **Dart** — Programming language
- **Supabase** — Authentication and backend services
- **PostgreSQL** — Database through Supabase
- **Google OAuth** — Google authentication
- **Figma** — UI/UX and wireframe design
- **Git/GitHub** — Version control

## Platform

PawCare is developed as an **iOS mobile application using Flutter**.

## Prerequisites

Install the following before running the project:

- Flutter SDK
- Xcode
- CocoaPods
- Git
- A configured Supabase project
- Google OAuth configuration if Google Sign-In is enabled

Check your Flutter setup with:

```bash
flutter doctor