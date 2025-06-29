📱 Smart Parking Reservation App (Frontend - Flutter)
This is the Flutter-based mobile application for the Smart Campus Parking System. It allows students and administrators to interact with parking features such as real-time reservations, availability predictions, user reporting, and navigation.

Features
- User Registration & Login (with role-based access)
- Real-time Parking Slot Reservation
- Parking Heatmap & Availability Prediction
- Navigation Assistance to Parking Locations
- Report Issues (with optional photo upload)
- Custom Parking Layout Handling
- Admin Tools (User & Parking Location Management)
- Persistent Login via SharedPreferences

Requirements
- Flutter SDK 3.x
- Dart SDK (comes with Flutter)
- Android Studio or VS Code (Flutter plugin installed)
- Physical Device or Emulator
- Internet connection (for API calls to backend)

Getting Started
1. Clone the Repository
  git clone https://github.com/Danielsuhaimi7/flutterproject.git
  cd flutterproject

3. Install Dependencies
  flutter pub get

5. Open config.dart and replace the base URL:
  const String baseUrl = 'http://<your-local-ip>:5000';
  If using an Android emulator, replace with 10.0.2.2. For a real device, use your computer's local IP.

7. Run the app
  flutter run

Notes
- The system uses role-based navigation (user vs admin).
- Data is persisted locally using SharedPreferences.
- Date and time formatting is consistent using Flutter’s native DateTime and TimeOfDay.

Related Repositories
- Backend - Flask API
- Required for full functionality.
- File from: https://github.com/Danielsuhaimi7/flutterproject_backend
