# 🚀 FCM Quick Setup Checklist

## ✅ Firebase Setup (5 minutes)

- [ ] Create Firebase project at console.firebase.google.com
- [ ] Download service account JSON (Settings → Service accounts → Generate key)
- [ ] Add Android app → Download `google-services.json`
- [ ] Add iOS app → Download `GoogleService-Info.plist`

## ✅ Android Setup (10 minutes)

- [ ] Place `google-services.json` in `android/app/`
- [ ] Add to `android/build.gradle`:
  ```gradle
  classpath 'com.google.gms:google-services:4.4.0'
  ```
- [ ] Add to `android/app/build.gradle`:
  ```gradle
  apply plugin: 'com.google.gms.google-services'
  
  dependencies {
      implementation platform('com.google.firebase:firebase-bom:32.7.0')
      implementation 'com.google.firebase:firebase-messaging'
  }
  ```
- [ ] Add FCM service to `AndroidManifest.xml` (see full guide)

## ✅ iOS Setup (15 minutes)

- [ ] Drag `GoogleService-Info.plist` into Xcode Runner folder
- [ ] Add "Push Notifications" capability in Xcode
- [ ] Add "Background Modes" → Enable "Remote notifications"
- [ ] Create APNs key at developer.apple.com
- [ ] Upload APNs key to Firebase Console

## ✅ Flutter Code (10 minutes)

- [ ] Add dependencies to `pubspec.yaml`:
  ```yaml
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
  ```
- [ ] Initialize Firebase in `main.dart`
- [ ] Create `lib/services/fcm_service.dart`
- [ ] Call `FCMService().initialize()` after login
- [ ] Call `FCMService().unregisterDevice()` on logout

## ✅ Supabase Config (2 minutes)

- [ ] Go to Supabase Dashboard → Edge Functions → Environment variables
- [ ] Add `FCM_SERVICE_ACCOUNT_JSON` = (paste entire service account JSON)
- [ ] Run: `supabase functions deploy send-push-notification`

## ✅ Test (5 minutes)

- [ ] Run app on Android device
- [ ] Check console for FCM token
- [ ] Send test from Firebase Console → Cloud Messaging
- [ ] Run app on iOS device (real device, not simulator)
- [ ] Check notification permissions granted
- [ ] Send test notification

---

## 🔑 Key Files Locations

```
project/
├── android/
│   ├── app/
│   │   ├── google-services.json ← Firebase Android config
│   │   └── build.gradle ← Add FCM dependencies here
│   └── build.gradle ← Add Google services plugin
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist ← Firebase iOS config
├── lib/
│   ├── main.dart ← Initialize Firebase
│   └── services/
│       └── fcm_service.dart ← FCM logic
└── supabase/
    └── functions/
        └── send-push-notification/
            └── index.ts ← Already updated with FCM
```

---

## 📞 Getting Help

- Full guide: `docs/FCM_SETUP_GUIDE.md`
- Firebase docs: https://firebase.google.com/docs/cloud-messaging
- Flutter Firebase: https://firebase.flutter.dev/docs/messaging/overview

---

**Total setup time: ~45 minutes**
