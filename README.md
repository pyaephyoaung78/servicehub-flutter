# ServiceHub Flutter Client

This Flutter application is the mobile client for ServiceHub. It connects to the Laravel backend and provides role-based experiences for customers, staff, and administrators.

## Technology Stack

- Flutter and Dart
- Dio for HTTP communication
- Provider for authentication state
- Flutter Secure Storage for the Sanctum token
- File Picker for payment-proof image/PDF selection

## Role-Based Application Flow

After login, the authentication provider loads the current user and the auth gate opens the appropriate application experience.

### Customer flow

1. Browse active service categories and services.
2. Create a booking with schedule, phone, address, and customer note.
3. Track booking status.
4. View quotations sent by the admin.
5. Accept or reject a quotation with an optional response note.
6. View the invoice after service completion.
7. Upload a payment proof with amount, payment method, receipt file, and optional note.
8. Track proof status: pending, approved, or rejected.
9. View recorded payments and the remaining invoice balance.

### Staff flow

1. View the staff profile and availability.
2. Review assigned bookings.
3. Accept or reject assignments.
4. Update accepted work through __on_the_way__, __in_progress__, and __completed__ states.

### Admin flow

The Flutter client includes admin screens for:

- Service categories and services.
- Bookings and booking details.
- Eligible staff and staff assignment.
- Staff profiles.
- Quotations.
- Invoices and payment recording.

The Laravel Blade dashboard is the main admin web panel and also provides payment-proof review, payment ledger, and reporting pages.

## End-to-End Business Workflow

~~~text
Customer creates booking
        ↓
Admin creates quotation for pending booking
        ↓
Customer accepts or rejects quotation
        ↓
Admin assigns staff after acceptance
        ↓
Staff performs and completes service
        ↓
Admin issues invoice
        ↓
Customer submits payment proof in Flutter
        ↓
Admin approves or rejects proof in web dashboard
        ↓
Approval records the invoice payment and updates the balance
~~~

### Important business rules

- Customers cannot set their own service price; the backend snapshots the trusted service price.
- A quotation is created only for a pending booking without another quotation.
- Staff assignment requires an accepted quotation.
- Accepted quotation pricing is copied into the invoice and is the invoice pricing source of truth.
- An invoice is created only for a completed booking, with one invoice per booking.
- Payments cannot exceed the invoice remaining amount.
- Only one payment proof can be pending for an invoice.
- A proof approval records a real invoice payment; uploading a proof alone does not change the invoice balance.

## Project Structure

~~~text
lib/
├── core/
│   ├── errors/                API error handling
│   ├── storage/               Secure token storage
│   └── network/               Dio API client and base URL
├── features/
│   ├── auth/                  Login, registration, Google auth, auth gate
│   ├── home/                  Role-based home navigation
│   ├── bookings/              Customer booking screens and service
│   ├── quotations/            Customer and admin quotation screens
│   ├── invoices/              Invoice screens, payments, and proof upload
│   ├── admin/                 Admin bookings, catalog, and staff screens
│   └── staff/                 Staff profile and assignment screens
└── main.dart                  Application entry point
~~~

Each feature generally contains:

- __models/__ for API response models.
- __services/__ for Dio requests.
- __screens/__ for Flutter UI.

## API Configuration

The backend URL is configured in:

__lib/core/network/api_client.dart__

The default URL is intended for the local development environment. For a physical device, use the Laravel machine's LAN IP address instead of __localhost__.

The client sends the Sanctum token as:

~~~text
Authorization: Bearer <token>
~~~

The Laravel API base path is __/api__.

## Payment-Proof Upload

The customer invoice detail screen displays existing payment proofs and provides the upload action when:

- The invoice is not fully paid.
- There is no other proof currently pending review.

The upload screen sends a multipart request to:

__POST /customer/invoices/{invoice}/payment-proofs__

Fields:

- __amount__
- __payment_method__
- __proof__ — JPG, JPEG, PNG, or PDF
- __note__ — optional

The upload response is shown as a proof status in the invoice detail screen. Admin approval happens in the Laravel web dashboard at __/admin/payment-proofs__.

## Local Setup

Make sure the Laravel backend is running and its API URL is reachable from the device or emulator.

~~~bash
flutter pub get
flutter run
~~~

For Android emulator development, configure the API host according to the emulator's network rules. For a physical device, use the backend computer's local network address and ensure the firewall allows the Laravel port.

## Validation

~~~bash
dart format lib
flutter analyze
flutter test
~~~

The analyzer may report informational lints in older screens. New code should not introduce errors or warnings.

## Backend Contract

The companion Laravel repository contains the authoritative business rules and API implementation:

- Authentication and role middleware.
- Booking status transitions.
- Quotation acceptance and expiry.
- Staff assignment rules.
- Accepted-quotation-to-invoice pricing propagation.
- Payment and payment-proof approval transactions.
- Admin reports.

Keep model parsing and service methods synchronized with the backend API resources when adding fields or workflow states.
