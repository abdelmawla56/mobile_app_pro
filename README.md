# SymbioTech2
SymbioTech
Assistive Mobile App for Deaf & Blind Users Using Smart Wearables & AI

1. Project Overview
Item
Details
App Name
SymbioTech
Developer
Youssef Ahmed Abdelmawla
Institution
Zewail City of Science and Technology
Email
s-youssef.elmawla@zewailcity.edu.eg
Platform
Android & iOS (Flutter)



Description:
SymbioTech is an innovative mobile application that leverages AI and smart wearables to empower deaf and blind individuals. By integrating real-time sign language recognition, printed text reading, and voice interaction, the app aims to create a seamless communication experience for users and their caregivers.

2. Purpose & Target Users
To enable deaf and blind users to communicate effectively and independently, while providing real-time assistance for caregivers and actionable insights for researchers.

Target Users
Purpose / Functionality
Deaf Persons
Convert sign language into spoken words
Blind Persons
Read printed text and convert it to speech
Caregivers
Provide real-time assistance and monitoring
Researchers
Explore AI-powered assistive technologies



3. Key Use Cases
#
Use Case
Technology
1
Sign Language to Speech
Smart Gloves 
2
Text Reading for Blind
ESP32-CAM Glasses 
3
Speech to Text
speech_to_text plugin 
4
Device Control
Bluetooth pairing 




Each use case integrates both software and hardware components to ensure accessibility, accuracy, and responsiveness. 


4. Development Roadmap – 3 Phases

Phase
Goal
Key Deliverables
Phase 1
UI & Navigation
Screens, responsive design, high-contrast interface
Phase 2
Core Functionality
Bluetooth integration, ESP32-CAM live stream, speech-to-text functionality
Phase 3
AI & Deployment
On-device TensorFlow Lite models (Sign Language + OCR), APK build, final deployment


5. Technology Stack
Layer
Tools
UI
Flutter, Material 3
Bluetooth
flutter_blue
Camera / Stream
camera, flutter_mjpeg
Hardware
ESP32-CAM










6. Design & Accessibility
High Contrast & Large Buttons: Optimized for low-vision users


Haptic Feedback: Provides tactile responses for interactions


Responsive Layout: Uses MediaQuery and LayoutBuilder for multiple screen sizes


Consistent Typography & Spacing: Roboto font, 8dp spacing for readability


Offline-first Approach: Ensures functionality without constant internet connection

7. Screenshots 


Description:
The home screen features four large, color-coded buttons for easy navigation:
Glasses → Live camera stream for text/scene recognition.
Gloves Speech Recognition → Converts speech to on-screen captions.
Gloves Sign Language → Translates hand gestures into text/speech (placeholder).
Connect Device → Pairs with external assistive hardware.
 Accessibility Features:
High-contrast blue buttons with bold white text.
Icons + labels for visual and cognitive clarity.
Spacious layout for users with motor impairments.


Description:
The side drawer provides quick access to core sections:
Home → Return to main dashboard.
Settings → Customize app preferences (future feature).
About App → Learn about SymbioTech’s mission.
Accessibility Features:
Clear iconography and consistent typography.
Dark background with white text for low-vision users.
Simple tap-to-navigate design.






8.Conclusion
SymbioTech is a complete assistive ecosystem that unites Flutter-based mobile development, IoT hardware, and AI-powered features.


