from confluent_kafka import Producer
import csv
import json
import os
import time
from datetime import datetime

from dotenv import load_dotenv


load_dotenv()

producer = Producer({
    "bootstrap.servers": "localhost:9092",
})

csv_file = "data/raw/olist_orders_dataset.csv"

with open(csv_file, newline="", encoding="utf-8") as file:
    reader = csv.DictReader(file)
    orders = list(reader)

orders.sort(key=lambda row: row["order_purchase_timestamp"])

simulation_speed = float(os.getenv("SIMULATION_SPEED", "1"))

previous_timestamp = None

for i, row in enumerate(orders):
    current_timestamp = datetime.strptime(
        row["order_purchase_timestamp"],
        "%Y-%m-%d %H:%M:%S"
    )

    if previous_timestamp is not None:
        time_difference = (
            current_timestamp - previous_timestamp
        ).total_seconds()

        wait_time = min(time_difference / simulation_speed, 5)
        time.sleep(wait_time)

    previous_timestamp = current_timestamp
    
    event = {
        "event_id": f"ORDER_CREATED_{row['order_id']}",
        "event_type": "ORDER_CREATED",
        "event_timestamp": row["order_purchase_timestamp"],
        "order_id": row["order_id"],
        "customer_id": row["customer_id"],
    }

    producer.produce(
        topic="order-events",
        key=event["order_id"],
        value=json.dumps(event),
    )

    print(f"Sent order: {event['order_id']}")

    if i == 99:
        break

producer.flush()