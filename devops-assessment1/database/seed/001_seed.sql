-- 100 deterministic bookings across multiple organizations, cities and statuses.
INSERT INTO hotel_bookings
    (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
    gen_random_uuid(),
    CASE (g % 4)
        WHEN 0 THEN '11111111-1111-1111-1111-111111111111'::uuid
        WHEN 1 THEN '22222222-2222-2222-2222-222222222222'::uuid
        WHEN 2 THEN '33333333-3333-3333-3333-333333333333'::uuid
        ELSE '44444444-4444-4444-4444-444444444444'::uuid
    END,
    'HOTEL-' || LPAD(((g % 12) + 1)::text, 3, '0'),
    CASE (g % 6)
        WHEN 0 THEN 'delhi'
        WHEN 1 THEN 'mumbai'
        WHEN 2 THEN 'bangalore'
        WHEN 3 THEN 'hyderabad'
        WHEN 4 THEN 'pune'
        ELSE 'chennai'
    END,
    CURRENT_DATE + ((g % 30) + 1),
    CURRENT_DATE + ((g % 30) + 3),
    ROUND((1200 + (g * 137.50))::numeric, 2),
    CASE (g % 4)
        WHEN 0 THEN 'confirmed'
        WHEN 1 THEN 'pending'
        WHEN 2 THEN 'cancelled'
        ELSE 'completed'
    END,
    CURRENT_TIMESTAMP - ((g % 45) || ' days')::interval
FROM generate_series(1, 100) AS g;

WITH numbered AS (
    SELECT
        b.*,
        row_number() OVER (ORDER BY b.created_at, b.id) AS rn
    FROM hotel_bookings b
)
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT
    id,
    CASE (rn::int % 3)
        WHEN 0 THEN 'booking.created'
        WHEN 1 THEN 'payment.updated'
        ELSE 'booking.status_changed'
    END,
    jsonb_build_object(
        'source', 'seed',
        'booking_status', status,
        'city', city
    ),
    created_at + interval '10 minutes'
FROM numbered
WHERE rn <= 60;
