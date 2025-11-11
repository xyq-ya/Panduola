Project: Panduola — concise instructions for AI coding agents

This repository is a Flutter mobile app (client) with a small Flask backend (API). Keep suggestions focused, minimal, and concrete; prefer small, testable changes and preserve existing app/navigation flows.

Key locations & big-picture
- Flutter app entry: `lib/main.dart` — app uses `provider` for state and Material 3 theme.
- UI screens: `lib/pages/` — `login_page.dart` is the first screen and shows how the app calls the backend.
- Simple global state: `lib/providers/user_provider.dart` — stores `id` and exposes `setId`.
- Backend API: `flask/app.py` and `flask/routes.py` — Flask blueprint mounted at `/api` with endpoints like `/login`, `/select_department`, `/select_team`, `/select_user`, `/user_info`.
- Backend config: `flask/config.py` stores DB connection constants (not secret-safe in repo).

Architecture & data flow (short)
- The Flutter app authenticates against the Flask API. `login_page.dart` posts JSON to `http://10.0.2.2:5000/api/login` (Android emulator host). On success the app expects `{"id": <user_id>}` and navigates to `HomePage(id: ...)` and sets `UserProvider.id`.
- Flask keeps a long-lived pymysql connection attached to `app.db_conn` and uses simple SQL queries returning JSON. Many endpoints return `{"code": 0, "data": ...}` or `{"error": ...}` for errors.

Developer workflows & commands
- Flutter run (typical): use Flutter tooling as usual. Entry point is `lib/main.dart`.
  - For Android emulator, backend references use `http://10.0.2.2:5000` (emulator → host machine).
  - To run app locally: use `flutter run` or run from IDE; tests use `flutter test` (see `test/widget_test.dart`).
- Backend: run Flask app for local development from project root:
  - Ensure Python dependencies installed (Flask, flask_cors, pymysql).
  - Start server: `python .\flask\app.py` (Windows PowerShell). It listens on 0.0.0.0:5000 with debug=True.

Project-specific conventions & gotchas
- Network host used by Flutter emulator: Android uses `10.0.2.2` to access host's `localhost`. iOS simulators use `localhost` directly. Windows/linux builds may need different host mappings.
- Backend DB configuration is in `flask/config.py` (plain text). Treat it as local dev config; do NOT assume production-safe secrets.
- SQL and JSON shapes are simple and sometimes inconsistent: field names returned by endpoints are noted with comments in `routes.py` (e.g. endpoint returns `dept_name`, `team_name`, `username` fields). Follow existing keys when parsing responses in Flutter.
- Global DB connection: Flask attaches a single connection to `app.db_conn`. Avoid closing that connection from handlers; use cursors and close cursors only.

When changing code, prefer small, local edits and include these checks
- For UI changes: run `flutter run` on an emulator, test login flow with provided Flask server.
- For backend changes: run `python .\flask\app.py` and use curl or Postman to exercise endpoints. Example POST body for login: `{"username":"alice","password":"pwd"}`.
- Follow current error/response conventions: HTTP 200 for success (often with `code:0`), and non-200 for auth/errors where currently used.

Examples to reference in-code
- Login request in `lib/pages/login_page.dart` — shows expected JSON request/response and navigation pattern.
- DB access pattern in `flask/routes.py` — grab `conn = current_app.db_conn`, get a cursor, execute SQL, fetch results, close cursor, and return JSON.

Safety and style
- Avoid adding new long-lived global resources; reuse existing `app.db_conn` for DB work in Flask.
- Keep UI strings and icons consistent with current Material 3 theme.
- Do not hardcode new secrets in repo; if needed, document required env vars and put placeholders in `flask/config.py`.

If anything here is unclear or you need more detail (build scripts, CI, or additional pages to reference), tell me which part and I'll expand or adjust.
