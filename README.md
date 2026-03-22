<div align="center">

<img src="assets/icon/app_icon.png" alt="Iqub Manager Logo" width="120" height="120"/>

# Iqub Manager

**The open-source rotating savings group (Iqub / ROSCA) manager — built with Flutter & Firebase**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue)](#)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-orange)](CONTRIBUTING.md)
[![Open Source Love](https://img.shields.io/badge/Open%20Source-%E2%9D%A4-red)](#)

[Features](#-features) · [Screenshots](#-screenshots) · [Quick Start](#-quick-start) · [Architecture](#-architecture) · [Roadmap](#-roadmap) · [Contributing](#-contributing)

</div>

---

## What is Iqub?

**Iqub** (ዕቁብ) is a traditional Ethiopian rotating savings and credit association — a group of trusted people who each contribute a fixed amount of money at regular intervals. Each round, one member receives the entire pot. This continues until every member has received the payout once.

It is practiced across the world under many names:

| Name | Region |
|---|---|
| Iqub / ዕቁብ | Ethiopia & Eritrea |
| Susu | Caribbean & West Africa |
| Tontine | Francophone Africa |
| Chit Fund | India |
| Hui / 會 | China & Taiwan |
| Paluwagan | Philippines |
| Tandas | Mexico & Latin America |

**Iqub Manager** brings this centuries-old tradition into the digital age — making it easy to create groups, track contributions, manage payouts, and maintain full transparency for every member, in real time.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 **Authentication** | Secure email/password login via Firebase Auth |
| 👥 **Group Management** | Create and manage multiple Iqub groups |
| 🔄 **Payout Rotation** | Automatic rotation order with position tracking |
| 💰 **Payment Tracking** | Mark contributions paid/unpaid per round with one tap |
| 📊 **Live Dashboard** | Real-time stats — current round, next payout member, total collected |
| 📜 **Full History** | Payment & payout history grouped by round |
| ⚙️ **Admin Controls** | Record payouts, manage members, generate payment records |
| 🔥 **Real-time Sync** | Firestore listeners — all members see live updates instantly |
| 📱 **Cross-platform** | Android & iOS from a single codebase |

---

## 📸 Screenshots

> Want to help? Add screenshots by contributing to [this issue](#).

| Login | Home | Iqub Detail | Payments |
|---|---|---|---|
| *coming soon* | *coming soon* | *coming soon* | *coming soon* |

---

## 🚀 Quick Start

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Firebase account](https://console.firebase.google.com) (free tier is enough)
- Android Studio or Xcode for device/emulator

### 1. Clone

```bash
git clone https://github.com/AKXtreme/iqub.git
cd iqub
flutter pub get
```

### 2. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com) → **Add project** → name it `iqub`
2. Enable **Authentication** → Email/Password
3. Enable **Firestore Database** → Start in test mode
4. Register Android app — package name: `com.iqub.iqub`
5. Register iOS app — bundle ID: `com.iqub.iqub`
6. Download `google-services.json` → put in `android/app/`
7. Download `GoogleService-Info.plist` → put in `ios/Runner/`
8. Generate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 3. Firestore Security Rules

Firebase Console → Firestore → Rules → Publish this:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /iqubs/{iqubId} {
      allow read: if request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.adminId;
      match /{subcollection=**} {
        allow read, write: if request.auth.uid in
          get(/databases/$(database)/documents/iqubs/$(iqubId)).data.memberIds;
      }
    }
  }
}
```

### 4. Run

```bash
flutter run
```

---

## 🏗 Architecture

Feature-first Clean Architecture with clear separation of concerns.

```
lib/
├── main.dart
├── firebase_options.dart        # Generated — gitignored, never commit
├── app/
│   ├── app.dart                 # Root widget
│   ├── router.dart              # GoRouter + auth redirect guard
│   └── theme.dart               # Design tokens, AppColors, AppTheme
├── core/
│   ├── extensions/              # DateTime, String extensions
│   ├── utils/                   # Form validators
│   └── widgets/                 # CustomButton, CustomTextField, ErrorView...
└── features/
    ├── auth/
    │   ├── domain/user_model.dart
    │   ├── data/auth_repository.dart
    │   ├── providers/auth_provider.dart
    │   └── ui/  login_screen, register_screen
    └── iqub/
        ├── domain/              # IqubModel, MemberModel, PaymentModel, PayoutModel
        ├── data/iqub_repository.dart
        ├── providers/iqub_provider.dart
        └── ui/  home, create, detail, members, payments, history + widgets/
```

### Stack

| Layer | Technology |
|---|---|
| UI | Flutter 3, Material 3, Google Fonts (Poppins) |
| State | Riverpod 2 — StreamProvider, StateNotifier |
| Navigation | GoRouter 14 |
| Backend | Firebase Auth + Cloud Firestore |
| Architecture | Feature-first Clean Architecture |
| Language | Dart 3 (fully null-safe) |

---

## 🗺 Roadmap

- [ ] Push notifications for payment reminders
- [ ] Multi-language: Amharic 🇪🇹, Oromo, Tigrinya, Arabic, Somali
- [ ] Offline mode (Isar local cache)
- [ ] Export to PDF / Excel
- [ ] Dark mode
- [ ] Invite members via link or QR code
- [ ] In-app payment integration (Telebirr, CBE Birr, M-Pesa)
- [ ] Web app (Flutter Web)
- [ ] Multi-admin groups

Have an idea? [Open a feature request](https://github.com/AKXtreme/iqub/issues/new?template=feature_request.md).

---

## 🤝 Contributing

We welcome contributions of all kinds — code, UI/UX design, translations, documentation, bug reports, and ideas.

**New to open source?** Look for issues labeled [`good first issue`](https://github.com/AKXtreme/iqub/issues?q=label%3A%22good+first+issue%22) — they are beginner-friendly and well-documented.

**Read the full guide:** 👉 [CONTRIBUTING.md](CONTRIBUTING.md)

```bash
# The short version
git checkout -b feature/your-feature
# make your changes
git commit -m "feat: describe your change"
git push origin feature/your-feature
# open a Pull Request
```

---

## 🛡 Security

Do not commit Firebase config files — they are already in `.gitignore`.
To report a vulnerability, see [SECURITY.md](SECURITY.md).

---

## 📄 License

MIT © [AKXtreme](https://github.com/AKXtreme) — see [LICENSE](LICENSE).

Free to use, modify, and distribute. If this helped you, a ⭐ star would mean a lot!

---

<div align="center">

**⭐ Star this repo if you find it useful — it helps others discover it!**

Made with ❤️ for the global Iqub / ROSCA community

</div>
