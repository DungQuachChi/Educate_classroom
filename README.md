================================================================================
                    DEPLOYMENT & ACCESS INFORMATION
================================================================================

WEB APPLICATION :
URL:  https://educate-classroom.web.app
Status: Active and ready for evaluation

ANDROID APK:
File: app-arm64-v8a-release. apk
Location: /android/app-arm64-v8a-release.apk
Min Android: 5.0 (API 21)
Size: ~26 MB

WINDOWS BUILD:
File: educate-classroom-windows-x64.zip
Location: /windows/educate-classroom-windows-x64.zip
Platform: Windows 10/11 (64-bit)
================================================================================
                         TEST ACCOUNT CREDENTIALS
================================================================================

INSTRUCTOR ACCOUNT (Pre-loaded with test data):
--------------------------------------------------
Username: admin
Password: admin
Email: admin@educate.com

PRE-LOADED DATA INCLUDES:
- 3 courses with complete content
- Student groups
- Course materials (PDFs, documents)
- Assignments with submissions
- Quizzes with questions
- Announcements
- Forum discussions

STUDENT ACCOUNTS (For testing student features):
--------------------------------------------------
Account 1:
Password: student123
Email: le.cuong@edu.vn

Account 2:
Password: student123
Email: hoang.em@edu.vn

Account 3:
Password: student123
Email: tran.binh@edu.vn

================================================================================
                    BUILDING & RUNNING INSTRUCTIONS
================================================================================

PREREQUISITES:
- Flutter SDK 3.x or higher (https://flutter.dev/docs/get-started/install)
- For Android: Android Studio with Android SDK
- For Windows: Visual Studio 2022 with C++ Desktop Development
- For macOS: Xcode 14+

---

QUICK START (Run from source):

1. Navigate to project directory:
   cd Educate_classroom

2. Install dependencies:
   flutter pub get

3. Run on desired platform:
   
   WEB:
   flutter run -d chrome
   
   ANDROID (with device/emulator connected):
   flutter run -d android
   
   WINDOWS:
   flutter run -d windows
   
   MACOS:
   flutter run -d macos

---

BUILDING FOR PRODUCTION:

WEB:
flutter build web --release
Output: build/web/

Deploy to Firebase Hosting:
firebase deploy --only hosting

ANDROID:
flutter build apk --release --target-platform android-arm64 --split-per-abi
Output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

WINDOWS:
flutter build windows --release
Output: build/windows/x64/runner/Release/

MACOS:
flutter build macos --release
Output: build/macos/Build/Products/Release/educate_classroom.app

================================================================================
                      INSTALLATION INSTRUCTIONS
================================================================================

WEB:
Simply open the provided URL in any modern web browser (Chrome recommended). 

ANDROID:
1. Enable "Install from Unknown Sources" in device settings
2. Transfer APK to device
3. Open APK file and install
4. Launch "Educate Classroom" app

WINDOWS:
1. Extract educate-classroom-windows-x64.zip
2. Navigate to extracted folder
3. Run educate_classroom.exe
4. No installation required (portable)

MACOS:
1.  Extract educate-classroom-macos.zip
2. Drag educate_classroom.app to Applications folder
3. Right-click app → Open (first time only, for security)
4. Login with test credentials

================================================================================
                      FEATURES EVALUATION GUIDE
================================================================================

LOGIN & AUTHENTICATION:
- Access web URL or launch app
- Use instructor credentials: admin/admin
- Verify role-based redirect to instructor dashboard

---

INSTRUCTOR FEATURES TO TEST:

1.  SEMESTER & COURSE MANAGEMENT:
   Location: Dashboard → Course Management
   Actions:
   - View existing semesters and courses
   - Create new semester
   - Create new course with cover image
   - Edit/Delete courses
   Key Feature: Course preselection - Click any course to access its management

2. STUDENT GROUP MANAGEMENT:
   Location: Course → Groups
   Actions:
   - View existing groups
   - Create new group
   - Add/remove students from group
   **KEY FEATURE: Real-time updates - Students appear instantly when added**

3. COURSE MATERIALS:
   Location: Course → Materials
   Actions:
   - Upload files (PDF, DOCX, PPTX, images)
   - View uploaded materials
   - Download materials
   - Delete materials
   **KEY FEATURE: Auto-selected course from course screen**

4. ASSIGNMENTS:
   Location: Course → Assignments
   Actions:
   - Create assignment with deadlines
   - View student submissions
   - Grade submissions
   - Download submitted files
   - Export grades to CSV
   **KEY FEATURE: Auto-selected course, CSV export**

5. QUIZZES:
   Location: Course → Quizzes
   Actions:
   - Manage question bank (Easy/Medium/Hard)
   - Create quiz with random question selection
   - Set time limits and max attempts
   - View student results
   - Export results to CSV
   **KEY FEATURE: Question bank updates when switching courses**
   
   To test:
   - Create quiz for Course A → Note question counts
   - Back → Select Course B → Create quiz
   - Question counts update automatically

6. ANNOUNCEMENTS:
   Location: Course → Announcements
   Actions:
   - Create announcements with attachments
   - Assign to specific groups or all students
   - View engagement (view counts)
   - Edit/Delete announcements
   **KEY FEATURE: Auto-selected course**

7. FORUMS:
   Location: Course → Forums
   Actions:
   - Create discussion topics
   - View/Reply to discussions
   - Upload attachments
   - Nested comments
   **KEY FEATURE: Real-time updates**

8.  MESSAGING:
   Location: Dashboard → Messages
   Actions:
   - Send messages to students
   - Real-time chat
   - File sharing
   **KEY FEATURE: Real-time message updates**

---

STUDENT FEATURES TO TEST:

Login as: student1/123456

1. COURSES:
   - View enrolled courses
   - Access course materials

2. ASSIGNMENTS:
   - View assignments with deadlines
   - Submit assignment files
   - Multiple attempts (if allowed)
   - View grades and feedback

3. QUIZZES:
   - Take timed quizzes
   - Submit answers
   - View results immediately
   - Review correct answers

4. ANNOUNCEMENTS:
   - View course announcements
   - Comment on announcements
   - Download attachments

5. FORUMS:
   - Participate in discussions
   - Create topics
   - Reply to comments

6. MESSAGING:
   - Chat with instructor
   - Receive messages in real-time

================================================================================
                      OPTIONAL FEATURES IMPLEMENTED
                         (EXTRA POINTS CLAIMED)
================================================================================

1. REAL-TIME UPDATES (Firestore Streams):
   Description: Live data synchronization using Firebase Firestore streams
   Where to test:
   - Add student to group → Student appears instantly
   - Post announcement → Students see it in real-time
   - Send message → Recipient receives immediately
   Technical: StreamBuilder widgets with Firestore listeners

2. FILE UPLOAD/DOWNLOAD SYSTEM (Firebase Storage):
   Description: Cloud-based file storage and retrieval
   Where to test:
   - Course Materials: Upload PDF, DOCX, images
   - Assignments: Submit/download files
   - Announcements: Attach files
   Technical: Firebase Storage integration with progress tracking

3. ADVANCED QUIZ SYSTEM:
   Description: Question bank with difficulty levels, random selection, timer
   Where to test:
   - Create questions with Easy/Medium/Hard difficulty
   - Create quiz with specific question distribution
   - Take quiz with countdown timer
   - Automatic grading and instant results
   Technical: Random selection algorithm, timer service, auto-submit

4. GROUP-BASED CONTENT DISTRIBUTION:
   Description: Assign content to specific student groups
   Where to test:
   - Create announcement for specific group
   - Assign quiz to selected groups
   - Students only see assigned content
   Technical: Group ID filtering in queries

5. DATA EXPORT FUNCTIONALITY:
   Description: Export grades and results to CSV
   Where to test:
   - Assignments: Export grades button
   - Quizzes: Export results button
   Technical: CSV generation and download

6. COURSE PRESELECTION & AUTO-NAVIGATION:
   Description: Smart course selection across management screens
   Where to test:
   - Click course → Click Materials → Course auto-selected
   - No need to choose course again in each section
   Technical: CourseModel parameter passing through navigation

7. NESTED COMMENTS SYSTEM:
   Description: Threaded discussions in forums and announcements
   Where to test:
   - Forum topics with reply functionality
   - Announcement comments with replies
   Technical: Recursive comment rendering

8. MULTI-PLATFORM DEPLOYMENT:
   Description: Single codebase deployed to 4 platforms
   Platforms:
   - Web (Firebase Hosting/GitHub Pages)
   - Android (ARM64 APK)
   - Windows (x64 executable)
   - macOS (Universal app)
   Technical: Platform-specific builds with conditional compilation

9. RESPONSIVE UI/UX ENHANCEMENTS:
   Description: Professional interface with error handling
   Features:
   - Loading states and progress indicators
   - Success/error notifications (SnackBars)
   - Form validation
   - Responsive layouts
   - Material Design 3 components
   Technical: Provider state management, form validators

TOTAL OPTIONAL FEATURES: 9 major enhancements

================================================================================
                    TECHNOLOGY STACK & ARCHITECTURE
================================================================================

FRONTEND:
- Flutter SDK 3.x
- Dart 3.x
- Material Design 3

BACKEND:
- Firebase Authentication (Email/Password)
- Firebase Firestore (NoSQL Database)
- Firebase Storage (File Storage)

STATE MANAGEMENT:
- Provider Pattern

KEY PACKAGES:
- provider: ^6.1.1 (State management)
- firebase_core, firebase_auth, cloud_firestore, firebase_storage
- file_picker, image_picker (File handling)
- intl (Date formatting)
- universal_html (Cross-platform HTML)
- url_launcher (Open URLs)

ARCHITECTURE:
- Model-View-Provider (MVP) pattern
- Service layer for Firebase operations
- Provider for state management
- Separate UI for instructor/student roles

================================================================================
                     REPRODUCING THE PROJECT
================================================================================

FIREBASE SETUP (If rebuilding from source):

1. Create Firebase project at console.firebase.google.com

2. Enable services:
   - Authentication → Email/Password
   - Firestore Database → Production mode
   - Storage → Production mode

3. Add apps:
   - Web app
   - Android app
   - iOS app (for macOS)

4. Download config files:
   - google-services.json → android/app/
   - GoogleService-Info.plist → ios/ and macos/
   - Web config → lib/firebase_options.dart

5.  Firestore Security Rules (for development):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

6. Storage Security Rules (for development):
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

INITIAL DATA SETUP:

The test accounts and sample data are already configured in the deployed
Firebase project. If setting up fresh:

1. Run the app
2. Register with email: admin/admin@educate.com, password: admin
3.  Manually set role to 'instructor' in Firestore users collection
4. Create semesters, courses, and add content
5. Register student accounts
6.  Enroll students in courses

================================================================================
                    TROUBLESHOOTING & KNOWN ISSUES
================================================================================

COMMON ISSUES:

1. Web: "dart:html not available"
   Solution: Already handled with universal_html package

2. Android: Installation blocked
   Solution: Enable "Install from Unknown Sources" in Settings

3. Windows: SmartScreen warning
   Solution: Click "More info" → "Run anyway"

4. macOS: "App can't be opened"
   Solution: Right-click → Open (first time only)

5. Login fails
   Solution: Check internet connection, Firebase may need authentication

PERFORMANCE NOTES:
- First load may take 2-3 seconds (Firebase initialization)
- Large file uploads depend on internet speed
- Real-time updates require stable internet connection

================================================================================
                         EVALUATION CHECKLIST
================================================================================

Core Requirements:
☑ Multi-platform deployment (Web + 1 mobile/desktop)
☑ Firebase integration (Auth + Firestore + Storage)
☑ Instructor features (Complete LMS functionality)
☑ Student features (Course access, submissions, quizzes)
☑ File upload/download
☑ Real-time data updates
☑ Role-based access control
☑ Professional UI/UX

Optional Features:
☑ Advanced quiz system with timer
☑ Group management
☑ CSV export
☑ Nested comments
☑ Real-time messaging
☑ Course preselection UX
☑ Multiple platform builds

Code Quality:
☑ Clean architecture
☑ State management (Provider)
☑ Error handling
☑ Form validation
☑ Loading states

Documentation:
☑ README with all required information
☑ Test accounts provided
☑ Build instructions included
☑ Feature guide provided
