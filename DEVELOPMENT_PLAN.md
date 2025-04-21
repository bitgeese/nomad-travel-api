# Travel Tracker Backend Development Plan (v1.1)

This plan outlines the development phases and tasks for building the backend API based on the `technical_specs.md`.

## Phase 0: Project Setup & Foundation

- [x] **Initialize Django Project:**
    - [x] Create Django project (`travel_tracker_api`).
    - [x] Create core app (`core`).
    - [x] Set up initial `settings.py` (DATABASE_URL, SECRET_KEY via environment variables).
    - [x] Configure PostgreSQL database connection.
- [x] **Integrate Core Libraries:**
    - [x] Add `djangorestframework` to requirements and `settings.py`.
    - [x] Add `psycopg2-binary` (or `psycopg`) to requirements.
- [x] **Set up Docker:**
    - [x] Create `Dockerfile` for the Django application.
    - [x] Create `docker-compose.yml` for local development (Django app, PostgreSQL, Redis).
    - [x] Create initial `requirements.txt` (or `pyproject.toml`).
- [x] **Basic CI/CD (Optional but Recommended):**
    - [x] Set up GitHub Actions (or similar) for basic linting/testing.

## Phase 1: User Authentication & Profile

- [ ] **Implement User Model:**
    - [ ] Create `users` app.
    - [ ] Define custom `User` model (extending `AbstractUser` or custom) including `apple_user_id`.
    - [ ] Configure `AUTH_USER_MODEL` in `settings.py`.
    - [ ] Create initial database migrations.
- [ ] **Email/Password Authentication:**
    - [ ] Add `djangorestframework-simplejwt` to requirements and `settings.py`.
    - [ ] Configure JWT settings (token lifetimes).
    - [ ] Implement `/api/auth/register/` endpoint (serializer, view).
    - [ ] Configure SimpleJWT's `/api/auth/login/email/` and `/api/auth/token/refresh/` URLs.
    - [ ] Implement `/api/auth/logout/` (optional token blacklisting).
- [ ] **Sign in with Apple:**
    - [ ] Add `python-jose` (or similar) to requirements.
    - [ ] Implement `/api/auth/login/apple/` endpoint:
        - [ ] View to receive Apple `identity_token`.
        - [ ] Service/logic to validate the token against Apple's public keys (JWKS).
        - [ ] Logic to find or create the user based on Apple User ID.
        - [ ] Issue JWT access/refresh tokens upon successful validation/user creation.
- [ ] **User Profile Management:**
    - [ ] Create `/api/profile/` endpoint (serializer, view - RetrieveUpdateAPIView) requiring authentication.

## Phase 2: Core Travel Data Management

- [ ] **Define Core Models:**
    - [ ] Create `countries` app.
    - [ ] Define `Country` model (`name`, `iso_code`, `is_schengen`).
    - [ ] Create `travel` app.
    - [ ] Define `TravelSegment` model (linking to `User` and `Country`, including all fields specified).
    - [ ] Create initial migrations for `countries` and `travel`.
- [ ] **Populate Country Data:**
    - [ ] Create a data migration or management command to pre-populate the `Country` table, including `is_schengen` flags.
- [ ] **Implement Travel Segment API:**
    - [ ] Create serializers for `TravelSegment`.
    - [ ] Implement `/api/travel-segments/` endpoint (ListCreateAPIView). Ensure it's scoped to the authenticated user.
    - [ ] Implement `/api/travel-segments/{id}/` endpoint (RetrieveUpdateDestroyAPIView). Ensure ownership check.
- [ ] **Implement Countries API:**
    - [ ] Create serializer for `Country`.
    - [ ] Implement `/api/countries/` endpoint (ReadOnlyModelViewSet or ListAPIView).

## Phase 3: Asynchronous CSV Import

- [ ] **Setup RQ (Redis Queue):**
    - [ ] Add `django-rq`, `rq`, `redis` to requirements.
    - [ ] Configure `django-rq` in `settings.py` (Redis connection).
    - [ ] Add RQ worker service to `docker-compose.yml`.
- [ ] **Implement Import Endpoint:**
    - [ ] Create `/api/travel-segments/import/csv/` endpoint (APIView).
    - [ ] Handle `multipart/form-data` file upload.
    - [ ] Enqueue a task using `django-rq` with user ID and file data/path.
    - [ ] Return `task_id` immediately.
- [ ] **Implement RQ Task:**
    - [ ] Create `tasks.py` within the `travel` app.
    - [ ] Define the CSV processing task function:
        - [ ] Parse CSV data (handle potential errors).
        - [ ] Add `pyairports` (or similar) to requirements.
        - [ ] Map IATA codes to countries using the library (handle mapping errors/logging).
        - [ ] Implement layover logic (detecting segments vs. layovers based on time/location).
        - [ ] Handle date/time parsing (assume UTC if timezone ambiguous).
        - [ ] Create `TravelSegment` instances for the user.
        - [ ] Update task status (e.g., using RQ job metadata or a dedicated model/cache).
- [ ] **Implement Status Check Endpoint:**
    - [ ] Create `/api/travel-segments/import/status/{task_id}/` endpoint (APIView).
    - [ ] Retrieve task status/result from RQ or the chosen storage mechanism.
    - [ ] Return status (Pending, Started, Success, Failure) and any relevant results or error messages.

## Phase 4: Visa Rules Engine & Calculation

- [ ] **Define Visa-Related Models:**
    - [ ] Create `visa_rules` app.
    - [ ] Define `VisaRule` model (as specified, consider `calculation_logic_ref`).
    - [ ] Define `UserVisaStatus` model (for caching results).
    - [ ] Create initial migrations.
- [ ] **Implement Schengen Calculation Logic:**
    - [ ] Create a service module/class within `visa_rules` for calculations.
    - [ ] Implement the Schengen 90/180 day rolling window logic:
        - [ ] Function takes `user` and `target_date`.
        - [ ] Fetches relevant `TravelSegment` data (Schengen countries, within the 180-day window).
        - [ ] Accurately calculates days spent, respecting entry/exit day counting.
- [ ] **Implement Calculation Endpoint & Caching:**
    - [ ] Create `/api/calculations/schengen/` endpoint (APIView).
    - [ ] Logic to check `UserVisaStatus` cache first.
    - [ ] If cache is stale or non-existent, trigger the calculation logic.
    - [ ] Update/create `UserVisaStatus` record with the result.
    - [ ] Return the current status (days used, window dates).
- [ ] **Cache Invalidation:**
    - [ ] Implement logic (e.g., using Django signals or overriding model `save`/`delete` methods) to invalidate/update `UserVisaStatus` when relevant `TravelSegment` records are created, updated, or deleted.

## Phase 5: Refinement & Deployment Prep

- [ ] **Add API Documentation:**
    - [ ] Integrate `drf-spectacular` or `drf-yasg` for OpenAPI/Swagger UI.
    - [ ] Ensure all endpoints are documented.
- [ ] **Implement Security Measures:**
    - [ ] Add Rate Limiting (`django-ratelimit`).
    - [ ] Review and apply Django's security checklist.
    - [ ] Ensure HTTPS is enforced (handled at deployment level).
- [ ] **Add Testing:**
    - [ ] Write unit tests for core logic (visa calculation, CSV parsing).
    - [ ] Write integration tests for API endpoints.
- [ ] **Refine Error Handling:**
    - [ ] Ensure consistent error responses across the API.
    - [ ] Improve logging for debugging.
- [ ] **Finalize Docker Configuration:**
    - [ ] Optimize Docker image size.
    - [ ] Ensure environment variables are correctly configured for production.
- [ ] **Prepare Deployment Documentation:**
    - [ ] Write basic instructions for deploying the containerized application to target platforms (Azure/Heroku/Render).

*(Future Phases might include Push Notifications, additional Visa Rules, etc.)* 