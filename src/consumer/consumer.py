from confluent_kafka import Consumer
import psycopg
import json


consumer = Consumer({
    "bootstrap.servers": "localhost:9092",
    "group.id": "order-consumer-db",
    "auto.offset.reset": "earliest",
    "enable.auto.commit": False,
})

conn = psycopg.connect(
    "host=localhost port=5433 dbname=ecommerce user=ecommerce password=ecommerce"
)

print("PostgreSQL connected")

consumer.subscribe(["order-events"])

print("Consumer started...")

try:
    while True:
        message = consumer.poll(1.0)

        if message is None:
            continue

        if message.error():
            print(f"Consumer error: {message.error()}")
            continue

        event = json.loads(message.value().decode("utf-8"))

        with conn.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO raw_order_events (
                    event_id,
                    event_type,
                    event_timestamp,
                    order_id,
                    customer_id
                )
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (event_id) DO NOTHING
                """,
                (
                    event["event_id"],
                    event["event_type"],
                    event["event_timestamp"],
                    event["order_id"],
                    event["customer_id"],
                ),
            )

        conn.commit()
        consumer.commit(message=message)

        print(f"Saved order: {event['order_id']}")

except KeyboardInterrupt:
    print("Consumer stopped")

finally:
    consumer.close()
    conn.close()