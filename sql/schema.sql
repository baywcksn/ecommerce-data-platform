CREATE TABLE IF NOT EXISTS raw_order_events (
    event_id TEXT PRIMARY KEY,
    event_type TEXT NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    order_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

SELECT COUNT(*) FROM raw_order_events;

SELECT COUNT(*) FROM raw_order_events;

SELECT *
FROM raw_order_events
ORDER BY received_at DESC
LIMIT 5;