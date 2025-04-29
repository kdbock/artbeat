# ArtBeat

ArtBeat is a Flutter-based mobile application designed to connect art enthusiasts with local art events, artists, and creative communities. The app provides a platform for discovering, sharing, and engaging with art in your area.

## Features

### 1. **User Authentication**
- **Sign Up & Login**: Users can register and log in to the app.
- **Secure Authentication**: Powered by Supabase for secure user management.

### 2. **Event Management**
- **Create Events**: Artists can create public or private art events with details like title, description, location, and images.
- **Discover Events**: Users can browse upcoming and past events, filter by category, and search by keywords or location.
- **Event Details**: View detailed information about events, including date, time, location, and artist profiles.
- **Favorite Events**: Save events to a personal favorites list for easy access.

### 3. **Community Engagement**
- **Community Feed**: A social feed where users can view posts, like, and comment.
- **Artist Profiles**: Explore artist profiles, including their bio, specializations, and links to their work.
- **Donations**: Support artists directly through in-app donation functionality.

### 4. **Art Locations & Tours**
- **Public Art Locations**: Discover public art installations and locations near you.
- **Walking Tours**: Explore curated walking tours of art locations with estimated distances and times.

### 5. **Maps Integration**
- **Google Maps**: Integrated for event locations, walking tours, and navigation.
- **Coordinates Input**: Users can manually input latitude and longitude for precise location details.

### 6. **Favorites**
- **Save Favorites**: Users can save events and art locations to their favorites list.
- **Manage Favorites**: Easily add or remove items from the favorites list.

### 7. (Upcoming) **Notifications**
- **Event Reminders**: Get notified about upcoming events (if enabled).

### 8. **Custom Themes**
- **Dynamic UI**: The app uses custom themes and Google Fonts for a visually appealing interface.

## Technical Details

### **Backend**
- **Supabase**: Used for authentication, database management, and file storage.
- **REST API**: Backend services are accessed via RESTful APIs.

### **Frontend**
- **Flutter**: Cross-platform framework for building the app.
- **Provider**: State management solution for managing app-wide state.

### **Maps & Location**
- **Google Maps Flutter**: For map rendering and location-based features.
- **Geolocator**: For fetching user location.

### **Storage**
- **Supabase Storage**: Used for storing images and other media files.

### **Payment Integration**
- **Stripe**: Integrated for processing donations to artists.

## Folder Structure

```
lib/
├── app.dart                # Main app entry point
├── core/                   # Core utilities and constants
│   ├── constants/          # Environment variables and constants
│   ├── themes/             # App themes and styles
│   ├── utils/              # Utility functions and helpers
│   └── widgets/            # Reusable widgets
├── features/               # Feature-specific modules
│   └── favorites/          # Favorites feature
├── routing/                # App routing and navigation
├── screens/                # UI screens
│   ├── auth/               # Authentication screens
│   ├── community/          # Community feed screens
│   ├── events/             # Event-related screens
│   ├── artist/             # Artist profile screens
│   ├── tours/              # Walking tours screens
│   └── ...                 # Other screens
├── services/               # Backend service integrations
│   ├── auth_service.dart   # Authentication service
│   ├── event_service.dart  # Event management service
│   ├── location_service.dart # Location-based services
│   ├── payment_service.dart # Payment processing service
│   └── social_media_service.dart # Social media interactions
└── widgets/                # Shared widgets
```

## Installation

### Prerequisites
- Flutter SDK (version 3.7.2 or higher)
- Dart SDK
- Android Studio or Xcode for mobile development

### Steps
1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```bash
   cd artbeat
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Environment Variables
Set up the following environment variables in `lib/core/constants/env.dart`:
- `SUPABASE_URL`
- `SUPABASE_KEY`
- `STRIPE_PUBLISHABLE_KEY`

## Contributing
Contributions are welcome! Please follow these steps:
1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes and push to your fork.
4. Submit a pull request.

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contact
For any inquiries or support, please contact [support@artbeat.com](mailto:support@artbeat.com).
