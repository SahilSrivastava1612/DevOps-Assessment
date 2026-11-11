# Database

PostgreSQL 16 is used for the local database assessment.

Schema:
- `hotel_bookings`
- `booking_events`

Initialization:
1. `docker compose up -d`
2. PostgreSQL executes migration SQL.
3. PostgreSQL executes seed SQL.
4. 100 bookings and booking events are available.

The optimized query uses the `(city, created_at)` composite index.
