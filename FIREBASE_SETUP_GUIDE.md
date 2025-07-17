# Firebase SSO Setup Guide

This guide covers the manual steps needed to complete the Firebase integration for Google and Apple Sign-In.

## ✅ Completed (Code Implementation)
- [x] Firebase authentication manager
- [x] Extended AuthManager with SSO methods
- [x] SSO UI components and login flow
- [x] Backend integration using existing Firebase DTOs
- [x] Testing interface for SSO functionality

## 📋 Required Manual Steps

### 1. Add Firebase SDK Dependencies

In Xcode:
1. Go to **File > Add Package Dependencies**
2. Add these package URLs:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Select these products:
   - FirebaseAuth
   - FirebaseCore
   - GoogleSignIn

### 2. Firebase Project Configuration

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project or use existing one
   - Enable Authentication

2. **Configure Authentication Providers**:
   - In Firebase Console → Authentication → Sign-in method
   - Enable **Google** and **Apple** sign-in
   - For Google: Note the Web client ID
   - For Apple: Configure Apple Sign-In (requires Apple Developer account)

3. **Add iOS App to Firebase**:
   - Add iOS app with bundle ID: `io.mindbuddy.app` (or your bundle ID)
   - Download `GoogleService-Info.plist`
   - **CRITICAL**: Add this file to your Xcode project root (drag into project navigator)

### 3. Apple Sign-In Configuration

1. **Apple Developer Console**:
   - Go to Certificates, Identifiers & Profiles
   - Configure App ID with "Sign In with Apple" capability
   - Create and download provisioning profiles

2. **Xcode Project Settings**:
   - Select your project target
   - Go to **Signing & Capabilities**
   - Add **Sign In with Apple** capability

### 4. URL Scheme Configuration

Add to `Info.plist` (or use Xcode's Info tab):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleSignIn</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 5. Backend Verification

Ensure your backend Firebase configuration is complete:
- Firebase Admin SDK configured
- `/auth/firebase` endpoint working
- User creation flow tested

## 🧪 Testing Steps

1. **Build the project** - should compile without errors
2. **Use Test Backend button** - test Google/Apple sign-in
3. **Check logs** for Firebase initialization
4. **Verify backend integration** with real Firebase tokens

## 🚨 Common Issues

1. **GoogleService-Info.plist not found**:
   - Ensure file is added to Xcode project bundle
   - Check file is included in target membership

2. **URL scheme errors**:
   - Verify REVERSED_CLIENT_ID matches GoogleService-Info.plist
   - Check Info.plist format

3. **Apple Sign-In not working**:
   - Verify Apple Developer account setup
   - Check provisioning profile includes Sign In with Apple

4. **Backend 500 errors**:
   - Ensure Firebase Admin SDK is configured in backend
   - Check Firebase project permissions

## 📱 UI Features

The implementation includes:
- **Modern SSO buttons** with loading states
- **Seamless integration** with existing email/password flow
- **Proper error handling** and user feedback
- **Test interface** for debugging SSO flows

## 🔄 Authentication Flow

1. User taps SSO button
2. Firebase SDK handles OAuth flow
3. App receives Firebase ID token
4. Token sent to backend `/auth/firebase` endpoint
5. Backend validates and returns JWT tokens
6. User authenticated in app

The implementation maintains compatibility with your existing authentication system while adding Firebase SSO capabilities.