# Peters Cuts iOS

[![Swift](https://img.shields.io/badge/Swift-5-FA7343?logo=swift&logoColor=white)](https://swift.org/)
[![Platform](https://img.shields.io/badge/Platform-iOS-000000?logo=apple&logoColor=white)](https://developer.apple.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

> Native iOS app for Peter's Cuts barbershop — appointment booking, SMS authentication, and schedule management.

## Quick Start

Open `petersios/Peters816.xcodeproj` in Xcode, select a simulator or device, and run.

## Architecture

```
Peters816/
├── App/           # App entry point and configuration
├── Models/        # Data models
├── Services/      # API client, auth, notifications
├── ViewModels/    # Business logic and state
└── Views/         # SwiftUI views
    ├── Auth/      # SMS login flow
    ├── Home/      # Main booking interface
    └── Components/
```

## Key Features

- **SMS Auth** — Phone-based login with JWT session management
- **Booking** — Browse availability and book/cancel appointments
- **Notifications** — Push reminders for upcoming appointments
- **Admin** — Schedule management for barbers

## Backend

Connects to the [Peters Cuts Backend](../../peters-cuts-web) — serverless API on AWS Lambda + DynamoDB.

---

**Tech Stack:** Swift · SwiftUI · iOS · JWT · Push Notifications
