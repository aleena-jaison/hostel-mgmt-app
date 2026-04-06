# Hostel Manager — Design Document

## Understanding Summary

- **What:** A hostel management mobile app (Flutter) for students + a web admin panel (Flutter Web) for the warden, sharing a single codebase
- **Why:** To digitize and streamline leave management, gate passes, check-in/out tracking, curfew enforcement, announcements, and student identity verification for a single hostel
- **Who:** ~100 students (mobile app) and 1 warden (web dashboard)
- **Backend:** Firebase (Firestore, Firebase Auth, Firebase Storage)
- **Key features:**
  - Leave requests with single-level warden approval
  - QR code-based gate pass for check-in/check-out
  - Periodic location check-ins during curfew hours (geofencing)
  - On-device face recognition for student identity verification
  - In-app announcements from warden to students
- **Admin:** Web-only interface for the warden to manage all operations

## Assumptions

- Firebase Auth (email/password) for login; face recognition is an additional identity verification step, not the login method
- Curfew times are configured by the warden via the admin panel
- QR codes are generated per approved gate pass and are single-use per direction (out/in)
- Location permissions are requested from students; app handles denial gracefully
- No offline-first requirement — expects internet connectivity for core operations
- No payment/fee module — purely operational management
- Android-focused for students (iOS optional/later)

---

## Architecture

### Approach: Feature-Based Architecture

Organized by feature modules. Each feature is a self-contained folder with its own screens, models, services, and state management.

### Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (mobile + web, single codebase) |
| State Management | Riverpod |
| Routing | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage) |
| QR Generation | `qr_flutter` |
| QR Scanning | `mobile_scanner` |
| Face Detection | `google_mlkit_face_detection` |
| Background Tasks | `workmanager` (Android periodic tasks) |
| Location | `geolocator` |
| Local Storage | `shared_preferences` |
| Image Capture | `camera` or `image_picker` |

### Project Structure

```
lib/
  main.dart
  app.dart                -> MaterialApp + GoRouter setup
  core/
    firebase/             -> Firebase init, Firestore refs
    theme/                -> App theme, colors, text styles
    constants/            -> Role enums, status enums
    utils/                -> Haversine calc, date helpers
  features/
    auth/
      screens/            -> LoginScreen, FaceEnrollScreen
      services/           -> AuthService (Firebase Auth wrapper)
      providers/          -> authProvider, currentUserProvider
    leave/
      models/             -> LeaveRequest
      screens/            -> LeaveFormScreen, LeaveListScreen (student), LeaveManageScreen (warden)
      services/           -> LeaveService
      providers/
    gate_pass/
      models/             -> GatePass
      screens/            -> GatePassScreen, QRDisplayScreen, QRScanScreen
      services/           -> GatePassService
      providers/
    geofencing/
      screens/            -> TrackingLogScreen (warden)
      services/           -> LocationService, GeofenceService
      providers/
    announcements/
      models/             -> Announcement
      screens/            -> AnnouncementFeed (student), AnnouncementManage (warden)
      services/           -> AnnouncementService
      providers/
    face_auth/
      screens/            -> FaceCaptureScreen, FaceVerifyScreen
      services/           -> FaceAuthService (ML Kit wrapper)
      providers/
    admin/
      screens/            -> AdminDashboard, StudentRoster, SettingsScreen
      widgets/            -> SidebarNav, SummaryCard
  shared/
    widgets/              -> AppScaffold, StatusBadge, ConfirmDialog
    models/               -> UserModel
```

---

## Firestore Data Model

### users/{userId}
| Field | Type | Notes |
|---|---|---|
| name | string | |
| email | string | |
| role | string | "student" or "warden" |
| roomNumber | string | Students only |
| phone | string | |
| faceEmbedding | string | Base64 encoded, students only |
| profileImageUrl | string | |
| createdAt | timestamp | |

### leaveRequests/{requestId}
| Field | Type | Notes |
|---|---|---|
| studentId | string | Ref to users |
| studentName | string | Denormalized |
| reason | string | |
| type | string | "home", "medical", "personal", "other" |
| fromDate | timestamp | |
| toDate | timestamp | |
| status | string | "pending", "approved", "rejected" |
| wardenRemarks | string? | Optional |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### gatePasses/{passId}
| Field | Type | Notes |
|---|---|---|
| studentId | string | |
| studentName | string | Denormalized |
| leaveRequestId | string? | Optional link |
| qrCodeData | string | Unique UUID token |
| purpose | string | |
| expectedOut | timestamp | |
| expectedIn | timestamp | |
| actualOut | timestamp? | Set on check-out scan |
| actualIn | timestamp? | Set on check-in scan |
| status | string | "active", "used_out", "used_in", "expired" |
| createdAt | timestamp | |

### locationCheckins/{checkinId}
| Field | Type | Notes |
|---|---|---|
| studentId | string | |
| latitude | double | |
| longitude | double | |
| isInsideGeofence | boolean | |
| timestamp | timestamp | |

### announcements/{announcementId}
| Field | Type | Notes |
|---|---|---|
| title | string | |
| body | string | |
| createdBy | string | Warden userId |
| createdAt | timestamp | |

### config/hostelSettings (single document)
| Field | Type | Notes |
|---|---|---|
| hostelName | string | |
| curfewStart | string | e.g., "22:00" |
| curfewEnd | string | e.g., "06:00" |
| geofenceCenter | map | { lat: double, lng: double } |
| geofenceRadiusMeters | int | |
| checkinIntervalMinutes | int | e.g., 15 |

---

## Feature Flows

### Authentication & Role-Based Routing

- Firebase Auth (email/password) for login
- Warden creates student accounts from admin panel; student receives password reset email
- On first login, student captures face for embedding storage
- Route based on `role` field: student -> mobile dashboard, warden -> web admin
- Route guards prevent cross-role access

**Routes:**
```
/login
/student/
/student/leave
/student/gate
/student/announcements
/admin/
/admin/leaves
/admin/passes
/admin/students
/admin/announce
/admin/settings
/admin/tracking
```

### Gate Pass & QR Code Flow

1. Student requests gate pass (purpose, expected out/in times, optional leave link)
2. Warden approves -> unique UUID token generated, stored as `qrCodeData`
3. Student sees QR code rendered from the token
4. At gate check-out: warden scans QR, validates, sets `actualOut`, status -> "used_out"
5. At gate check-in: warden scans QR, validates, sets `actualIn`, status -> "used_in"
6. One active gate pass per student at a time
7. Unused passes expire past `expectedOut` time
8. Face verification required before displaying QR code

### Geofencing & Curfew Monitoring

1. Warden configures geofence center, radius, curfew times, check-in interval in settings
2. During curfew hours, if student has no active "used_out" gate pass:
   - Background task (workmanager) triggers every N minutes
   - Fetches GPS, calculates distance from geofence center (haversine)
   - Writes locationCheckins doc
3. Students with active gate passes skip location check-ins
4. Outside curfew hours: no tracking
5. Warden views violations (isInsideGeofence == false) on dashboard, filterable by date/student
6. Location permission denied: warden sees "no check-in data" flag

### Face Authentication

- **Enrollment:** First login -> capture face via camera -> ML Kit extracts face embedding -> stored as base64 in user doc. Reference photo uploaded to Firebase Storage.
- **Verification:** Before showing gate pass QR -> camera captures live face -> new embedding -> cosine similarity against stored embedding -> threshold 0.85 -> pass/fail
- Max 3 retry attempts, then locked out (contact warden)
- ML Kit is free, on-device, no network needed for comparison

### Leave Management

- Student submits: type, reason, from date, to date -> status "pending"
- Warden views pending list, approves/rejects with optional remarks
- Student sees leave history with status indicators
- On approval, student can generate a linked gate pass

### Announcements

- Warden creates: title + body -> saved with timestamp
- Student sees reverse-chronological feed
- Unread indicator via local SharedPreferences timestamp comparison
- Warden can view/delete past announcements

---

## Admin Dashboard

**Sidebar navigation:**
- Dashboard (home) — summary cards
- Students — roster, details, register new
- Leave Requests — pending/approved/rejected tabs
- Gate Passes — active list, scan QR, void passes
- Tracking — curfew violation log
- Announcements — create, view, delete
- Settings — hostel config

**Dashboard summary cards:**
| Card | Source |
|---|---|
| Pending Leaves | leaveRequests where status == "pending" |
| Students Out | gatePasses where status == "used_out" |
| Violations Today | locationCheckins where isInsideGeofence == false, today |
| Total Students | users where role == "student" |

Real-time updates via Firestore snapshot listeners.

---

## Firestore Security Rules (High-Level)

- Students can **read**: own user doc, own leave requests, own gate passes, all announcements, hostelSettings
- Students can **create**: leave requests, location check-ins
- Students can **update**: own faceEmbedding field only
- Warden can **read/write**: everything
- No public access

---

## Decision Log

| # | Decision | Alternatives Considered | Reason |
|---|---|---|---|
| 1 | Feature-based architecture | Layer-based, Clean Architecture | Right balance of structure and simplicity for single-hostel scale |
| 2 | Firebase backend | Supabase | User preference; fits real-time needs with Firestore listeners |
| 3 | Flutter Web for admin | Separate React/Next.js app | Single codebase, shared models and logic |
| 4 | On-device face recognition (ML Kit) | Cloud-based (Rekognition), device biometrics | Private, offline-capable, verifies the student not just the phone owner |
| 5 | Periodic location check-ins | Continuous tracking, event-based only | Balances reliability with battery life |
| 6 | QR code gate pass | Face verification at gate, manual warden check | Clean, scannable, works with any device |
| 7 | In-app announcements only | Push notifications, email | Simplicity for v1 at small scale |
| 8 | Single approval (warden only) | Multi-level, auto-approval rules | One warden, one hostel — no need for complexity |
| 9 | Riverpod for state management | Bloc, Provider, GetX | Modern, testable, good web support |
| 10 | GoRouter for routing | Auto-route, Navigator 2 raw | Web URL support, role-based guards, well-maintained |
| 11 | Workmanager for background tasks | Background Fetch, AlarmManager direct | Flutter-native, supports periodic Android tasks |
| 12 | Client-side violation detection | Cloud Functions alerts | Avoids Firebase paid tier; warden checks dashboard |
| 13 | Local unread tracking (SharedPreferences) | Firestore per-user read status | No extra writes/reads for a simple feature |
