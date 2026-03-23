# Changelog

All notable changes to **Iqub Manager** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Push notifications for payment reminders
- Multi-language support (Amharic, Oromo, Tigrinya)
- Offline mode with local caching
- Export reports to PDF

---

## [1.0.0] - 2026-03-23

### Added
- User authentication (email/password via Firebase Auth)
- Create and manage Iqub groups with name, description, amount, frequency
- Add and remove members with automatic payout rotation
- **Drag-to-reorder** payout rotation order before the first round
- Set contribution amount and frequency (weekly / bi-weekly / monthly)
- Track payments per round (paid / unpaid) with one tap
- Automatic payout rotation management with round advancement
- Dashboard with current round, next payout member, and total collected
- Full payment history grouped by round
- Full payout history with payout records
- Admin-only controls (record payout, manage members, generate payments)
- **Profile screen** — edit name and phone, member since date
- **Dark mode** with persistent toggle (light/dark switch in profile)
- Modern UI with Poppins font, Material 3, custom theme
- Firebase Firestore real-time sync with security rules
- Firestore composite indexes for optimal query performance
- Custom app icon (green bowl with gold coins)
- GitHub Actions CI (lint, analyze, APK build)

[Unreleased]: https://github.com/AKXtreme/iqub/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AKXtreme/iqub/releases/tag/v1.0.0
