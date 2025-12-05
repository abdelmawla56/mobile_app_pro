# 🦾 SymbioTech – Assistive Application for the Deaf and Blind  
An AI-powered Flutter application designed to support visually and hearing-impaired users through smart-device functionalities such as camera assistance, image recognition, sign-language features, and Bluetooth-connected wearable devices.

---

## 🚀 Features

### 🔍 1. **Camera Stream + On-Device AI (TFLite)**
- Uses the device camera to capture frames.
- Runs a TensorFlow Lite model (`best_int8.tflite`) locally for fast predictions.
- Displays real-time classification results.

### 🌐 2. **Flask API Integration**
- Captures a frame from the device camera.
- Sends it to a Flask server via `MultipartRequest`.
- Receives prediction + confidence score from the backend.

### 🤟 3. **Sign Language Camera Preview**
- Opens a clean camera preview.
- (Future) For integration with sign-language recognition models.

### 📡 4. **Bluetooth Device Scanner**
- Uses `flutter_blue_plus` to:
  - Scan nearby Bluetooth devices.
  - List discovered devices.
  - Connect to selected devices.
- Managed with Provider + ChangeNotifier for reactive UI updates.

### ⭐ 5. **Rate Us (Form + Firestore)**
- Users can select a star rating and submit an optional comment.
- Form validation and UI feedback.
- All submissions stored in **Firebase Firestore** (`ratings` collection).

### 📬 6. **Contact Us (Form + Firestore)**
- Validates name, email, and message.
- Saves support messages to Firestore (`contact_messages` collection).
- Shows SnackBar confirmation messages.

### ⚙️ 7. **Settings (SharedPreferences)**
Stores user preferences permanently:
- Enable/Disable Notifications  
- Enable/Disable Vibration  
- Dark Mode Toggle (UI Preview)

Data is saved locally using **SharedPreferences**, loaded automatically on app startup.

---

## 🧠 **Phase 2 Requirements (Completed)**

| Requirement          | Status | Implementation Summary |
|---------------------|--------|-------------------------|
| Data Storage        | ✔️     | Firebase Firestore + SharedPreferences |
| State Management    | ✔️     | Provider + ChangeNotifier for Bluetooth service |
| API Integration     | ✔️     | Flask prediction using image upload |
| Forms + Validation  | ✔️     | Rate Us + Contact Us fully validated and saved |
| Device Features     | ✔️     | Camera, Bluetooth, and AI inference |

---

## 🛠️ **Technologies Used**

### **Frontend (Flutter)**
- Flutter 3+
- Dart
- Provider (state management)
- SharedPreferences
- Camera plugin
- Flutter Blue Plus
- TFLite Flutter

### **Backend (Optional)**
- Flask API for external model predictions
- Python & Machine Learning models

### **Cloud**
- Firebase Core
- Firebase Firestore

---

## 📸 **Screenshots (Optional)**  
_Add screenshots here later for UI demonstration._

---

## 🔧 Setup Instructions

### 1. Install dependencies
```bash
flutter pub get
