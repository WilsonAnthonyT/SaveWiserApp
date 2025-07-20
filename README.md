# SaveWiser – Release Flutter App

1. Set up the development environment (VS Code, Flutter, etc.)
2. Run / Build the app locally
3. Build and publish the app to the Google Play Store

## 🔧 Prerequisites – First-Time Setup

> Skip this section if you already have Flutter and VS Code with the necessary tools installed.

### 1. Install Flutter SDK

- Go to: https://flutter.dev/docs/get-started/install
- Follow the installation guide for your OS (Windows/macOS/Linux)
- Install all the important extensions (flutter, flutter widgets and dart) in the VSCode
- After installing, open a terminal and run:
  ```bash
  flutter doctor
  ```
  if the android thing is missing, go to the step 2

### 2. Install Android Studio (to retreive the android sdk)
- Go to : https://developer.android.com/studio
- During the setup process, make sure to donwload the following components:
  
✅ Android SDK

✅ Android SDK Platform-Tools

✅ Android Emulator

✅ Android Virtual Device (AVD)

✅ Android SDK cmdline-tools

-After installing Android Studio, run flutter doctor again to verify the Android SDK is detected. If it's not, ask ChatGPT for help on setting up the path.


For a more comprehensive guide, follow the steps by watching this video below:
**Watch THIS:**
>> https://youtu.be/0x2M69D7wKw?si=ZIGk6iydon84uxE7
(note: the new android studio layout might be different compared to the video, just ask chatgpt for that :))

### To Build the App Locally
- Clone the repository to your IDE
>> https://github.com/WilsonAnthonyT/SaveWiserApp.git
- Make sure to always change directory to savewiser (the folder where pubspec.yaml is located)
  ```bash
  cd savewiser
  ```
- Run the following in the terminal
  ```bash
  flutter pub get
  ```
  If you want to Build the App locally:
  ```bash
  flutter build apk
  ```
wait until the whole processes are finished, then you can download the apk_release file
(inside the SaveWiserApp\savewiser\build\app\outputs\flutter-apk)
- Or if you want to run the app immediately"
  ```bash
  flutter run
  ```
  Then select the devices where'd you want the app to run on

**How to clone a repository**
>> https://youtu.be/ILJ4dfOL7zs?si=iiQkzEsB7scCZ8hz

### 3. Publish the App on Google Play
>> https://docs.flutter.dev/deployment/android

To publish the app, you’ll need:

- A [Google Play Developer Account](https://play.google.com/console) ($25 one-time)
- Java jdk in order to obtain the keystore
- The `.aab` file (Android App Bundle), which you can generate using:

```bash
flutter build appbundle --release
```

watch the following tutorial for clarity
>> https://youtu.be/ZxjgV1YaOcQ?si=to1RUt3Uut8xZd_3


Environment variable should consists of
- flutter\bin
- AppData\Local\Android/SDK
- Java\jdk-24\bin







