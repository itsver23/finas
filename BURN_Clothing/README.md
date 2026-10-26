# BURN Clothing — Flutter + Supabase + Xendit (starter)

This is an **editable Flutter source project**, not a compiled APK. Uses the uploaded loading-screen artwork and recreates the 14-screen BURN UI as Flutter widgets. The uploaded student form pattern (`StatefulWidget`, controllers, validation, `saveData()`) is adapted to `AddressPage` using Supabase.

## Setup
1. Install Flutter SDK, Android SDK and run `flutter doctor`.
2. Create a **new** Supabase project. Run `supabase/schema.sql` in its SQL editor (once; policy creation statements are not idempotent).
3. Add real products to `products` with `active=true`, stock and public HTTPS `image_url`. No real products are included; sample demo items appear only if no Supabase config is provided. Demo items cannot be checked out.
4. Install Supabase CLI, link your project, deploy `create-checkout` (JWT verification enabled), and deploy `xendit-webhook` with JWT verification disabled **only for the webhook**. The webhook validates the Xendit callback token itself.
5. Set Edge Function secrets `XENDIT_SECRET_KEY` and `XENDIT_CALLBACK_TOKEN`. Set the Xendit invoice webhook URL to `https://<project-ref>.supabase.co/functions/v1/xendit-webhook`. Use **test** credentials first. Never put secret keys in the app.
6. In the Flutter project run:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkeXFwY25lYWhnaGh1dHR3amRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5MDM2NDIsImV4cCI6MjEwODQ3OTY0Mn0.Ltz2KXTlhcqydwWnRjPLMQQ9kPxppHJY-907ihiSF5o --dart-define=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkeXFwY25lYWhnaGh1dHR3amRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5MDM2NDIsImV4cCI6MjEwODQ3OTY0Mn0.Ltz2KXTlhcqydwWnRjPLMQQ9kPxppHJY-907ihiSF5o

Build a test APK:

```bash
flutter build apk --debug --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

## Important limits before production
- UI is a functional **starter**, not a fully audited live shop. Flutter SDK was unavailable in this environment, so the app was **not compiled or device-tested**.
- Products currently have category and price but no persistent size/color variant SKU; product detail size/color selection is UI only. Add a `product_variants` table and store selected variants in the cart before launch.
- Webhook sets payment status but does **not** yet atomically decrement stock or reserve inventory; add an idempotent Postgres transaction/RPC for stock management and race conditions.
- Checkout currently uses the first saved address; implement address selection, confirmation and editing.
- The Xendit WebView does not itself confirm payment. The verified server webhook determines order status; users should open My Orders to check status.
- Payment/order errors may leave a pending order. Add expiration/cleanup and retry flow before production.
- Login supports email/password; Google/Apple buttons are not implemented.
- The image mockup contains illustrative products, prices, and personal details; these are not imported as real customer records.
- Use the **real Android release keystore** and review RLS, product stock, webhook security, returns/refunds, privacy policy, and payment gateway live approval before public release.

## Source structure

- `lib/main.dart` — app bootstrap and theme
- `lib/config/` — Supabase environment config and UI helpers
- `lib/models/` — product model and demo catalog
- `lib/services/` — store/cart state and Xendit checkout request
- `lib/screens/` — individual screens and a `screens.dart` export barrel

The payment webhook and invoice creation backend remain in `supabase/functions/`. The app has not been compiled here; test with `flutter analyze` and `flutter run` on your Flutter installation.
