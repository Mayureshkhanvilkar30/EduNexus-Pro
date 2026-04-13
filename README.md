 EduNexus Pro: AI-Powered Study Assistant
​EduNexus Pro is an intelligent, gamified study ecosystem designed to bridge the gap between digital assistance and academic discipline. Built using Flutter and Google Gemini 1.5 Flash, it automates student workflows by transforming natural language queries into actionable habits.
​🚀 Key Features
​Intelligent Intent Extraction: Leverages Gemini 1.5 Flash to extract study tasks and timestamps from casual user chats.
​Automated Habit Syncing: Once a task is identified, the system automatically updates the Cloud Firestore database and schedules localized reminders.
​OCR Note Scanner: Integrated with Google ML Kit to digitize physical textbook notes and generate AI summaries.
​Gamified Reward System: Features Daily Streaks (🔥) and XP Points to incentivize consistency and reward academic progress.
​Premium Glassmorphic UI: A modern, translucent interface designed for a superior user experience and focus.
​🛠️ Tech Stack
​Frontend: Flutter (Dart)
​Backend: Firebase (Authentication & Cloud Firestore)
​Generative AI: Google Gemini API
​Machine Learning: Google ML Kit (for OCR)
​State Management: Provider / Bloc (Specify what you used)
​Local Notifications: flutter_local_notifications
​📊 System Architecture
​The application follows a clean architecture pattern, ensuring a separation of concerns between the UI, business logic (AI & OCR services), and the backend (Firebase).
​📥 Installation
Clone the repository:
git clone https://github.com/mayureshkhanvilkar30@gmail.com/EduNexus-Pro.git
Navigate to the project directory:
cd EduNexus-Pro
Install dependencies:
flutter pub get
Setup Firebase:
Create a project on Firebase Console.
Add your google-services.json (Android) and GoogleService-Info.plist (iOS).
Run the application:
flutter run
Development & Documentation
This project was developed as a final-year academic project. It includes a comprehensive documentation report (SRS, UML Diagrams, and Testing reports) created following IEEE standards.
🤝 Contributors
Mayuresh Khanvilkar - Lead Developer
Collaborators: Kanishka, Nitin, and Prem.
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.