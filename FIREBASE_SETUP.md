# Firebase Setup Instructions

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

## Step 2: Get Your Firebase Configuration

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. Click the **Web** icon (`</>`) to add a web app
4. Register your app with a nickname (e.g., "Pigeon Club Web")
5. Copy the Firebase configuration object

## Step 3: Create Environment File

Create a `.env` file in the root directory of your project with the following variables:

```env
VITE_FIREBASE_API_KEY=your-api-key-here
VITE_FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your-messaging-sender-id
VITE_FIREBASE_APP_ID=your-app-id
```

Replace the placeholder values with your actual Firebase configuration values.

## Step 4: Enable Firebase Services

### Authentication
1. Go to **Authentication** in Firebase Console
2. Click **Get started**
3. Enable **Email/Password** or other sign-in methods you need

### Firestore Database
1. Go to **Firestore Database** in Firebase Console
2. Click **Create database**
3. Choose **Start in test mode** (for development) or **Start in production mode**
4. Select a location for your database

### Storage (Optional)
1. Go to **Storage** in Firebase Console
2. Click **Get started**
3. Start in test mode or production mode
4. Choose a location

## Step 5: Install Dependencies

Dependencies are already installed. If you need to reinstall:

```bash
npm install
```

## Step 6: Start Your Development Server

```bash
npm run dev
```

Your Firebase integration is now ready to use!

## Usage

Import Firebase services in your components:

```javascript
import { auth, db, storage } from './firebase/config';
```

