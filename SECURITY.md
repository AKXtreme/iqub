# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | ✅ Yes             |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability, please report it responsibly:

1. **Email:** open a private security advisory on GitHub:
   - Go to the [Security tab](https://github.com/AKXtreme/iqub/security/advisories/new)
   - Click "Report a vulnerability"

2. Include in your report:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

3. You will receive a response within **48 hours**.

4. We will coordinate a fix and disclosure timeline with you.

## Security Best Practices for Contributors

- Never commit `google-services.json`, `GoogleService-Info.plist`, or `firebase_options.dart`
  — these are listed in `.gitignore`
- Never hardcode API keys, secrets, or credentials in source code
- Always use Firebase Security Rules to protect Firestore data
- Keep dependencies up to date (`flutter pub outdated`)
