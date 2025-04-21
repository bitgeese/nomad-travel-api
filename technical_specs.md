# Backend Technical Specification: Travel Time Tracker App v1.0

**Version:** 1.1  
**Date:** 2025-04-15 (Updated)

## 1. Overview

This document outlines the technical specifications for the backend system (v1.1) of the Travel Time Tracker application. The backend provides the API, data storage, synchronization logic, and calculation engine to support the iOS client application. The primary purpose of the app is to help users track time spent in different countries for personal records and visa compliance.

This version focuses on user authentication, data persistence, API endpoints for travel management, CSV import processing, and the initial implementation of the Schengen Area 90/180-day rule calculation.

## 2. Target Platform & Technology

- **Language/Framework:** Python / Django
- **Database:** Relational Database (PostgreSQL recommended)
- **API:** RESTful API using JSON (Leveraging Django REST Framework recommended)
- **Asynchronous Tasks:** RQ (Redis Queue)
- **Deployment:** Cloud hosting platform (Azure, Heroku, or Render preferred) via Docker containers.

## 3. Core Responsibilities

- User authentication and session management (Email/Password, Sign in with Apple).
- Secure storage and management of user data (profile, travel segments).
- Providing API endpoints for the iOS client to Create, Read, Update, Delete (CRUD) travel data.
- Data synchronization logic to support multiple client devices.
- Processing uploaded CSV flight data asynchronously, including airport code mapping and layover logic.
- Calculating time spent in countries based on travel segments.
- Implementing and calculating visa rule compliance (initially Schengen 90/180).
- Triggering push notifications based on calculated events (e.g., visa limit approaching).
- Ensuring data security, privacy, and system scalability.

## 4. Architecture

- **Client-Server Model:** Acts as the server, responding to requests from the iOS client via a RESTful API.
- **Monolithic Application:** Django project structure. Keep code modular (separate Django apps) for maintainability.
- **Database Interaction:** Django ORM.

## 5. Backend Specification (Python/API)

### Authentication:

- Implement token-based authentication (e.g., JWT via djangorestframework-simplejwt).
- **Token Strategy:** Use short-lived access tokens (e.g., 15-60 minutes) and longer-lived refresh tokens (e.g., 7-30 days). Refresh tokens should be securely handled (e.g., stored appropriately by the client, potentially rotated).
- Endpoints for email/password registration, login, password reset. Secure password hashing (Django's default hasher or bcrypt) is mandatory.
- Endpoint for validating Apple Sign-In credentials (identity token) and issuing session tokens. Requires integration with Apple's authentication services.

### Database Schema (Conceptual - using Django ORM models):

- **Users** (Extending Django's AbstractUser or custom): 
  - id, email (unique, nullable), password (hashed), apple_user_id (unique, nullable), created_at, updated_at.

- **Countries**: 
  - id (PK), name (unique), iso_code (unique, e.g., 'US', 'DE'), is_schengen (boolean, indexed). Needs pre-population.

- **TravelSegments**: 
  - id (PK), user (FK to Users, indexed), departure_country (FK to Countries), arrival_country (FK to Countries), departure_date (DateField), arrival_date (DateField), mode_of_transport (CharField with choices: 'Flight', 'Train', 'Car', 'Bus', 'Ferry', 'Other'), entry_point (CharField, optional), purpose (CharField, optional), notes (TextField, optional), created_at (DateTimeField auto_now_add), updated_at (DateTimeField auto_now). Indexing on user and dates is crucial.

- **VisaRules**: 
  - id (PK), name (unique, e.g., 'Schengen 90/180'), description (TextField), region_countries (ManyToManyField to Countries), max_days (IntegerField), period_days (IntegerField), calculation_logic_ref (CharField identifying the calculation function/module). Designed for extensibility.

- **UserVisaStatus**: 
  - id (PK), user (FK, indexed), rule (FK, indexed), days_used (IntegerField), window_start_date (DateField), window_end_date (DateField), last_calculated_at (DateTimeField). Caches calculation results. Needs invalidation logic.

### API Endpoints (RESTful - using Django REST Framework):

- `/api/auth/register/` (POST)
- `/api/auth/login/email/` (POST - using SimpleJWT endpoint) -> Returns {access, refresh} tokens.
- `/api/auth/login/apple/` (POST): Body {identity_token}. Validates token, creates/links user, returns {access, refresh} tokens.
- `/api/auth/token/refresh/` (POST - using SimpleJWT endpoint): Body {refresh}. Returns {access} token.
- `/api/auth/logout/` (POST): Requires Auth Token. (Optional: blacklist refresh token if using blacklist app).
- `/api/profile/` (GET, PUT): Requires Auth Token. Manages user details.
- `/api/travel-segments/` (GET, POST): Requires Auth Token. (ListCreateAPIView)
  - GET: Returns paginated list of user's segments.
  - POST: Creates a new manual segment. Returns created segment.
- `/api/travel-segments/{id}/` (GET, PUT, DELETE): Requires Auth Token. (RetrieveUpdateDestroyAPIView)
- `/api/travel-segments/import/csv/` (POST): Requires Auth Token. Accepts multipart/form-data with CSV file. Enqueues processing task using RQ. Returns a task_id.
- `/api/travel-segments/import/status/{task_id}/` (GET): Requires Auth Token. Checks the status of the import task (Pending, Started, Success, Failure) and potentially returns results/errors. Client polls this endpoint.
- `/api/calculations/schengen/` (GET): Requires Auth Token. Returns current Schengen status (UserVisaStatus data) for the user. Triggers calculation if cache is stale.
- `/api/notifications/settings/` (GET, PUT): Requires Auth Token. (Future: Allow configuring notifications).
- `/api/countries/` (GET): No Auth required (or optional). Returns list of countries for client UI population.

### Visa Rule Engine:

- Initial implementation for Schengen 90/180 rule within a dedicated Django app or service module.
- Input: User object, current date. Fetches relevant TravelSegments.
- Logic: Implements the rolling 180-day window calculation.
- Design: Modular design referenced by VisaRules.calculation_logic_ref.
- Caching: Update UserVisaStatus after calculation.

### CSV Import Processing (Asynchronous Task via RQ):

- RQ worker process picks up tasks.
- Input: User ID, CSV file content/path.
- Parse CSV rows (handle errors).
- Airport Code Mapping: Use a Python library (e.g., pyairports initially) to map IATA codes to Countries. Log errors for unmappable codes. Consider fallback/manual mapping options later.
- Timestamp Parsing: Handle date/time fields correctly. Attempt to determine timezone; if ambiguous, assume UTC.
- Layover Logic: Implement as described previously.
- Create TravelSegment records. Check for potential duplicates.
- Update task status in backend storage (e.g., Django cache or a dedicated model) accessible via the `/api/travel-segments/import/status/{task_id}/` endpoint.

### Push Notification Triggering:

- Periodic task (e.g., daily via django-q scheduler or cron) or triggered upon relevant data changes.
- Recalculate visa statuses.
- If thresholds met, trigger APNS push via libraries like django-push-notifications or custom integration. Requires storing user device tokens securely.

### Data Sync Logic: 
Standard REST API CRUD. Use updated_at timestamps for client-side caching and conflict resolution ("Last Write Wins").

### Security:

- HTTPS mandatory.
- Use Django's security features (CSRF protection for web forms if any, password hashing, etc.).
- Input validation via Django Forms / DRF Serializers.
- Authentication/Authorization via DRF permissions.
- Keep dependencies updated (pip-audit or similar).
- Rate Limiting (e.g., django-ratelimit).
- Data Encryption at rest for sensitive fields if necessary (e.g., django-cryptography).

## 6. Data Models (API Representation - JSON)

*(Remains the same as previous spec version)*
- User
- Country
- TravelSegment
- SchengenStatus

## 7. Assumptions & Future Considerations

- **Scalability:** Design for stateless application servers. Database optimization is key.
- **Airport Code Data:** Library requires updates. External API might be needed later for better accuracy.
- **Timezones:** Assume UTC storage. Explicit timezone handling might be needed in future versions.
- **Extensibility:** Modular Django app structure aids future expansion.
- **Asynchronous Processing:** Requires setting up Redis and RQ workers.
- **Refresh Token Handling:** Requires secure storage and management strategy on the client-side.
