# Contributing to Iqub Manager

First of all — **thank you** for taking the time to contribute! 🎉

Iqub Manager is an open-source project and every contribution matters, whether it's a bug fix, a new feature, a translation, improved documentation, or simply reporting an issue. This guide will walk you through everything you need to know to contribute effectively.

**Before you start:** Please read our [Code of Conduct](CODE_OF_CONDUCT.md). By contributing, you agree to abide by it.

---

## Table of Contents

1. [Code of Conduct](#1-code-of-conduct)
2. [Getting Started](#2-getting-started)
3. [Development Workflow](#3-development-workflow)
4. [Code Style Guidelines](#4-code-style-guidelines)
5. [Testing](#5-testing)
6. [Commit Guidelines](#6-commit-guidelines)
7. [Pull Request Process](#7-pull-request-process)
8. [Areas of Contribution](#8-areas-of-contribution)
9. [Project Structure](#9-project-structure)
10. [Firebase Setup for Contributors](#10-firebase-setup-for-contributors)
11. [Reporting Bugs](#11-reporting-bugs)
12. [Suggesting Features](#12-suggesting-features)
13. [Translations](#13-translations)
14. [Community & Communication](#14-community--communication)
15. [Recognition](#15-recognition)

---

## 1. Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable
behavior by opening a private GitHub security advisory.

---

## 2. Getting Started

### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Dart SDK](https://dart.dev/get-dart) `>=3.0.0` (bundled with Flutter)
- [Git](https://git-scm.com/)
- A Firebase account (free tier is enough) — see [Section 10](#10-firebase-setup-for-contributors)
- Android Studio (for Android emulator) or Xcode on macOS (for iOS simulator)

### Fork & Clone

```bash
# 1. Fork the repo on GitHub (click the Fork button top-right)

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/iqub.git
cd iqub

# 3. Add the upstream remote so you can pull in future changes
git remote add upstream https://github.com/AKXtreme/iqub.git
```

### Install Dependencies

```bash
flutter pub get
```

### Set Up Firebase

See [Section 10](#10-firebase-setup-for-contributors) for the full Firebase setup.
You need your own Firebase project to run the app locally.

### Verify Everything Works

```bash
flutter analyze          # should show: No issues found!
flutter test             # should show: All tests passed
flutter run              # should launch on your emulator/device
```

---

## 3. Development Workflow

### Always work on a branch

Never commit directly to `main`. Always create a new branch for your work:

```bash
# Pull latest changes from upstream first
git fetch upstream
git checkout main
git merge upstream/main

# Create your branch
git checkout -b <type>/<short-description>

# Examples:
git checkout -b feat/push-notifications
git checkout -b fix/payment-toggle-bug
git checkout -b docs/update-firebase-setup
git checkout -b i18n/amharic-translations
```

### Branch naming convention

| Prefix | Use for |
|---|---|
| `feat/` | New features |
| `fix/` | Bug fixes |
| `docs/` | Documentation only |
| `refactor/` | Code refactoring (no functional change) |
| `test/` | Adding or fixing tests |
| `i18n/` | Translations |
| `chore/` | Build, CI, dependency updates |
| `ui/` | UI/UX improvements |

### Keep your branch up to date

```bash
git fetch upstream
git rebase upstream/main
```

---

## 4. Code Style Guidelines

This project follows the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style) and Flutter best practices.

### Key rules

**Formatting**
```bash
# Always format before committing
dart format lib/ test/
```

**Naming**
```dart
// Classes — PascalCase
class IqubRepository {}

// Variables, functions, parameters — camelCase
final contributionAmount = 500.0;
void markPaymentPaid() {}

// Constants — camelCase (Dart style, not SCREAMING_SNAKE)
const maxRounds = 24;

// Private members — leading underscore
final _formKey = GlobalKey<FormState>();
```

**File names — snake_case**
```
iqub_model.dart       ✅
IqubModel.dart        ❌
iqubModel.dart        ❌
```

**Imports — ordered alphabetically, separated by blank lines**
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. Local project
import '../../../app/theme.dart';
import '../domain/iqub_model.dart';
```

**Widgets — keep them small and focused**
```dart
// Prefer extracting sub-widgets as private classes within the same file
class _SectionHeader extends StatelessWidget { ... }

// Or separate reusable widgets into core/widgets/ or feature/ui/widgets/
```

**Providers — always in the providers/ layer**
```dart
// Good — defined in iqub_provider.dart
final iqubProvider = StreamProvider.family<IqubModel?, String>(...);

// Bad — provider defined inside a screen file
```

**No hardcoded colors or text styles**
```dart
color: AppColors.primary    // ✅
color: Color(0xFF1A56DB)    // ❌ — use AppColors instead

style: Theme.of(context).textTheme.titleLarge   // ✅
style: TextStyle(fontSize: 18, fontWeight: ...)  // ❌
```

### Linting

The project uses `flutter_lints`. Run analysis before every PR:

```bash
flutter analyze
# Must show: No issues found!
```

---

## 5. Testing

We aim for meaningful test coverage — not 100% for the sake of it, but tests that catch real bugs.

### Run tests

```bash
flutter test                          # all tests
flutter test test/unit/               # unit tests only
flutter test --coverage               # with coverage report
```

### Test structure

```
test/
├── unit/
│   ├── models/          # Model serialization tests
│   └── repositories/    # Repository logic tests (with mocks)
└── widget/              # Widget tests for key screens
```

### Writing tests

```dart
// Unit test example — model serialization
test('IqubModel.fromDoc parses correctly', () {
  final doc = FakeDocumentSnapshot(data: {
    'name': 'Office Iqub',
    'contributionAmount': 500.0,
    ...
  });
  final iqub = IqubModel.fromDoc(doc);
  expect(iqub.name, 'Office Iqub');
  expect(iqub.contributionAmount, 500.0);
});
```

### Guidelines
- Every new model must have a serialization/deserialization test
- Every repository method with business logic should have a unit test
- Bug fixes must include a regression test
- You do NOT need to test Flutter framework internals

---

## 6. Commit Guidelines

We follow the **Conventional Commits** specification. This makes the changelog
and release notes auto-generatable.

### Format

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### Types

| Type | When to use |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation changes only |
| `style` | Formatting, missing semicolons — no logic change |
| `refactor` | Code restructuring — no feature or bug change |
| `test` | Adding or fixing tests |
| `chore` | Build process, dependency updates, CI |
| `i18n` | Internationalization / translations |
| `perf` | Performance improvements |

### Examples

```bash
git commit -m "feat(payments): add PDF export for payment history"
git commit -m "fix(auth): handle expired session gracefully on app resume"
git commit -m "docs: add Amharic setup instructions to README"
git commit -m "refactor(iqub): extract payout logic into dedicated service"
git commit -m "i18n: add Amharic translations for all auth strings"
git commit -m "chore(deps): upgrade firebase_auth to 5.4.0"
```

### Rules
- Use **imperative mood**: "add feature" not "added feature"
- Keep the subject line under **72 characters**
- Reference issues: `fix(payments): correct rounding error (closes #42)`
- One logical change per commit — don't bundle unrelated changes

---

## 7. Pull Request Process

### Before opening a PR

- [ ] Your branch is up to date with `upstream/main`
- [ ] `flutter analyze` shows **No issues found!**
- [ ] `flutter test` passes
- [ ] `dart format lib/ test/` has been run
- [ ] You have tested on a real device or emulator
- [ ] You have updated documentation if needed

### Opening the PR

1. Push your branch: `git push origin feat/your-feature`
2. Go to GitHub → your fork → **Compare & pull request**
3. Fill in the PR template completely (title, description, screenshots if UI change)
4. Link any related issues: `Closes #123`
5. Request a review if you know who to ask, otherwise leave it to maintainers

### PR title format

Follow the same Conventional Commits format:
```
feat(members): add QR code invite for new members
fix(dashboard): correct total collected calculation for paused groups
```

### Review process

- A maintainer will review within **3–5 business days**
- Please respond to review comments within **7 days** or the PR may be closed
- Once approved, a maintainer will merge it — do not merge your own PRs
- Squash merging is preferred for cleaner history

### PR size

Keep PRs focused and small. Large PRs are harder to review and more likely to conflict.
If your change is large, split it into smaller PRs that build on each other.

---

## 8. Areas of Contribution

Not sure where to start? Here are the most impactful areas:

### 🐛 Bug Fixes
Check [open bugs](https://github.com/AKXtreme/iqub/issues?q=is%3Aissue+is%3Aopen+label%3Abug).
Even small fixes are valuable.

### ✨ New Features
Check the [roadmap in README](README.md#-roadmap) or
[feature requests](https://github.com/AKXtreme/iqub/issues?q=is%3Aissue+label%3Aenhancement).
Comment on the issue before starting to avoid duplication.

### 🌍 Translations (High Priority!)
The app currently only supports English. We need:
- **Amharic (አማርኛ)** — primary target
- Oromo (Afaan Oromoo)
- Tigrinya (ትግርኛ)
- Somali
- Arabic
- French (for Francophone Africa)
- Hindi (for Indian Chit Fund users)

See [Section 13](#13-translations) for how to contribute translations.

### 📸 Screenshots & Demo
Add real screenshots to `docs/screenshots/` and update the README table.
A demo GIF or video would be amazing for discoverability.

### 📖 Documentation
Improve the README, add code comments, write wiki pages, record a setup tutorial.

### 🧪 Tests
We need more test coverage. Check uncovered areas with `flutter test --coverage`.

### 🎨 UI/UX Design
If you are a designer:
- Improve existing screens
- Design new features (dark mode, onboarding, etc.)
- Create a proper design system / Figma file

### ♿ Accessibility
- Add semantic labels to all widgets
- Test with TalkBack (Android) and VoiceOver (iOS)
- Ensure minimum touch target sizes

### ⚡ Performance
- Profile the app with Flutter DevTools
- Reduce unnecessary rebuilds
- Optimize Firestore query patterns

---

## 9. Project Structure

```
iqub/
├── lib/
│   ├── main.dart                    # Entry point, Firebase.initializeApp()
│   ├── firebase_options.dart        # 🔒 Gitignored — each dev generates their own
│   ├── app/
│   │   ├── app.dart                 # Root MaterialApp.router
│   │   ├── router.dart              # GoRouter, named routes, auth guard
│   │   └── theme.dart               # AppTheme, AppColors — all design tokens here
│   ├── core/
│   │   ├── extensions/
│   │   │   └── datetime_ext.dart    # .formatted, .relative, .monthYear
│   │   ├── utils/
│   │   │   └── validators.dart      # Form field validators
│   │   └── widgets/
│   │       ├── custom_button.dart   # Primary / outlined / text button variants
│   │       ├── custom_text_field.dart
│   │       ├── error_view.dart      # Full-screen and compact error states
│   │       └── loading_overlay.dart
│   └── features/
│       ├── auth/
│       │   ├── domain/user_model.dart        # UserModel (Equatable, Firestore)
│       │   ├── data/auth_repository.dart     # register, signIn, signOut, watchCurrentUser
│       │   ├── providers/auth_provider.dart  # authStateProvider, authNotifierProvider
│       │   └── ui/
│       │       ├── login_screen.dart
│       │       └── register_screen.dart
│       └── iqub/
│           ├── domain/
│           │   ├── iqub_model.dart           # IqubModel, IqubStatus, IqubFrequency
│           │   ├── member_model.dart         # MemberModel
│           │   ├── payment_model.dart        # PaymentModel
│           │   └── payout_model.dart         # PayoutModel
│           ├── data/iqub_repository.dart     # All Firestore CRUD + batch operations
│           ├── providers/iqub_provider.dart  # StreamProviders + IqubActionsNotifier
│           └── ui/
│               ├── home_screen.dart
│               ├── create_iqub_screen.dart
│               ├── iqub_detail_screen.dart
│               ├── members_screen.dart
│               ├── payments_screen.dart
│               ├── history_screen.dart
│               └── widgets/
│                   ├── iqub_card.dart
│                   ├── member_tile.dart
│                   ├── payment_tile.dart
│                   └── stats_card.dart
├── test/
│   ├── unit/
│   └── widget/
├── android/
│   └── app/
│       └── google-services.json     # 🔒 Gitignored — download from Firebase Console
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist # 🔒 Gitignored — download from Firebase Console
├── assets/
│   └── icon/
│       └── app_icon.png
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/
│   └── PULL_REQUEST_TEMPLATE.md
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md                  # This file
├── LICENSE
├── README.md
└── SECURITY.md
```

### Firestore Data Model

```
/users/{userId}
  - id, name, email, phone, photoUrl, createdAt

/iqubs/{iqubId}
  - id, name, adminId, contributionAmount, frequency
  - totalRounds, currentRound, memberIds[], payoutOrder[]
  - status (active|paused|completed), startDate, createdAt
  /members/{memberId}
    - id, iqubId, userId, name, phone
    - payoutPosition, hasReceivedPayout, joinedAt
  /payments/{paymentId}
    - id, iqubId, memberId, memberName, roundNumber
    - amount, isPaid, dueDate, paidAt
  /payouts/{payoutId}
    - id, iqubId, memberId, memberName, roundNumber
    - amount, payoutDate, createdAt
```

---

## 10. Firebase Setup for Contributors

Because `google-services.json`, `GoogleService-Info.plist`, and `firebase_options.dart`
are gitignored (they contain API keys), each contributor must set up their own Firebase project.

**This is free and takes about 5 minutes.**

```bash
# After cloning:

# 1. Create a Firebase project at console.firebase.google.com
#    - Enable Authentication (Email/Password)
#    - Enable Firestore (test mode)
#    - Register Android app: com.iqub.iqub
#    - Register iOS app: com.iqub.iqub

# 2. Download config files and place them:
#    android/app/google-services.json
#    ios/Runner/GoogleService-Info.plist

# 3. Generate firebase_options.dart
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Run
flutter run
```

---

## 11. Reporting Bugs

Found a bug? Please check [existing issues](https://github.com/AKXtreme/iqub/issues) first
to avoid duplicates. If it's new, open a bug report using the template.

A good bug report includes:
- **Flutter version:** `flutter --version`
- **Device/OS:** e.g., Pixel 7 / Android 14, iPhone 15 / iOS 17
- **Steps to reproduce** — numbered, precise
- **Expected behavior**
- **Actual behavior**
- **Screenshots or screen recording** if possible

[Open a Bug Report →](https://github.com/AKXtreme/iqub/issues/new?template=bug_report.md)

---

## 12. Suggesting Features

Have an idea? Check the [roadmap](README.md#-roadmap) and
[open feature requests](https://github.com/AKXtreme/iqub/issues?q=label%3Aenhancement) first.

If your idea is new, open a feature request. Great requests explain:
- **The problem** it solves (not just "add X")
- **Who benefits** from it
- **How it might work** — rough idea is fine

[Open a Feature Request →](https://github.com/AKXtreme/iqub/issues/new?template=feature_request.md)

---

## 13. Translations

Translations are one of the highest-impact contributions for this project.
Iqub is used across the Horn of Africa and the diaspora — supporting local languages
makes the app accessible to millions more people.

### How to contribute a translation

> Full internationalization (i18n) infrastructure is on the roadmap.
> When it's ready, translation files will live in `lib/l10n/`.
> Until then, open an issue to coordinate.

[Open a Translation Issue →](https://github.com/AKXtreme/iqub/issues/new?title=i18n%3A+[Language+Name]&labels=i18n)

---

## 14. Community & Communication

- **GitHub Issues** — bugs, features, questions
- **GitHub Discussions** — general discussion, ideas, show & tell
- **Pull Requests** — code review and collaboration

When in doubt, open an issue first before writing code — it saves everyone time
to align on the approach before implementation.

---

## 15. Recognition

Every contributor is valued. Here's how we recognize contributions:

- Your name and GitHub profile will appear in the contributors list
- Significant contributions will be highlighted in the `CHANGELOG.md`
- We follow the [All Contributors](https://allcontributors.org/) specification
  — contributions of all types (code, docs, design, ideas, translations) are recognized

**Thank you for making Iqub Manager better for everyone.** 🙏
