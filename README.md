# ShopFlow — Real-Time E-Commerce Data Platform

A portfolio Data Engineering project that simulates a near real-time e-commerce data platform using historical Olist e-commerce data.

The project demonstrates an event-driven data ingestion pipeline using Python, Apache Kafka, and PostgreSQL, with a focus on reliability, idempotency, error handling, and reproducibility.

---

## Project Overview

**ShopFlow** is a fictional e-commerce company that needs newly created order events to become available for downstream analytics within a few minutes.

The original Olist dataset is historical and static. Therefore, this project uses a Python event producer to replay historical order events based on their original purchase timestamps and publish them to Apache Kafka as simulated real-time events.

The goal is not to pretend that the Olist dataset is a live source, but to build a realistic engineering environment for practicing event-driven data ingestion.

---

## Architecture

```text
                 Historical Olist Dataset
                          |
                          v
                 Python Event Producer
                          |
                          v
                 Apache Kafka Cluster
                      order-events
                          |
                          v
                  Python Kafka Consumer
                          |
                          v
                     PostgreSQL
                   raw_order_events
```

### Data Flow

1. The Python producer reads historical orders from the Olist dataset.
2. Orders are sorted by their original `order_purchase_timestamp`.
3. The producer simulates event arrival using configurable simulation modes.
4. Order events are published to the Kafka `order-events` topic.
5. The Kafka consumer reads events using a consumer group.
6. Events are validated and inserted into PostgreSQL.
7. PostgreSQL prevents duplicate events using an `event_id` primary key.
8. Kafka offsets are committed only after successful database processing.

---

## Why Kafka?

Kafka is used to introduce an event-streaming layer between the event producer and the database.

This provides several important engineering characteristics:

- Decoupling between producers and consumers
- Durable event storage
- Consumer offset management
- Ability to replay events
- Consumer groups
- A foundation for multiple downstream consumers

The project therefore separates **event production** from **event processing** instead of writing directly from Python into PostgreSQL.

---

## Why PostgreSQL?

PostgreSQL is currently used as the raw data storage layer.

The first ingestion table is:

```text
raw_order_events
```

Its purpose is to preserve the incoming order events before further transformation and analytical modeling.

Current columns:

| Column | Description |
|---|---|
| `event_id` | Unique identifier for the event |
| `event_type` | Type of event, currently `ORDER_CREATED` |
| `event_timestamp` | Original business/event timestamp |
| `order_id` | Olist order identifier |
| `customer_id` | Customer identifier |
| `received_at` | Timestamp when the event was stored in PostgreSQL |

An important distinction is maintained between:

- **Event time** — when the order originally occurred
- **Ingestion time** — when the platform received and stored the event

---

## Reliability & Data Engineering Concepts

Milestone 1 focuses on several real-world data engineering concepts.

### Idempotent Ingestion

The same event may be delivered more than once.

The database uses `event_id` as the primary key and handles duplicate events with:

```sql
ON CONFLICT (event_id) DO NOTHING
```

This ensures that replaying the same event does not create duplicate records.

### Kafka Offset Management

The consumer uses manual offset commits.

The offset is committed **after** the database transaction succeeds.

Conceptually:

```text
Kafka Event
    |
    v
Process Event
    |
    v
Write to PostgreSQL
    |
    v
Commit DB Transaction
    |
    v
Commit Kafka Offset
```

This prevents the consumer from acknowledging an event before it has been successfully persisted.

### Error Handling

Database failures trigger a transaction rollback.

Malformed JSON or missing event fields are detected and reported instead of silently failing.

More advanced retry and Dead Letter Queue mechanisms will be introduced in later milestones.

---

## Simulation Modes

Because the source dataset is historical, the producer supports configurable event simulation.

### Accelerated Mode

Historical time differences are compressed.

For example, a historical gap of 100 seconds can be simulated as approximately 10 seconds.

Configuration:

```env
SIMULATION_MODE=accelerated
SIMULATION_SPEED=10
SIMULATION_MAX_WAIT_SECONDS=5
```

### Realtime Mode

The producer preserves the original time difference between historical events.

```env
SIMULATION_MODE=realtime
```

The simulation design allows the same historical dataset to behave like an event source without modifying the original data.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Python | Event producer and Kafka consumer |
| Apache Kafka | Event streaming |
| PostgreSQL | Raw event storage |
| Docker | Local infrastructure |
| Git | Version control |
| GitHub | Source code and project documentation |

---

## Project Structure

```text
ecommerce-data-platform/
├── config/
├── dags/
├── data/
│   ├── processed/
│   └── raw/
├── docs/
├── scripts/
├── sql/
│   └── schema.sql
├── src/
│   ├── consumer/
│   │   └── consumer.py
│   ├── producer/
│   │   └── producer.py
│   └── test_db.py
├── tests/
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md
```

Raw datasets and environment secrets are intentionally excluded from Git.

---

## Data Source

**Brazilian E-Commerce Public Dataset by Olist**

The dataset contains approximately 100,000 orders from the Brazilian e-commerce ecosystem between 2016 and 2018.

Source:

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset contains multiple related tables covering areas such as:

- Orders
- Customers
- Products
- Sellers
- Order Items
- Payments
- Reviews
- Geolocation
- Product category translations

Only the required raw dataset is used locally. The original files are not committed to this repository.

---

## Running the Project

### 1. Start infrastructure

```bash
docker compose up -d
```

This starts the local Kafka and PostgreSQL services.

### 2. Configure environment

Create `.env` from the provided example:

```bash
cp .env.example .env
```

### 3. Run the Kafka consumer

```bash
python src/consumer/consumer.py
```

### 4. Run the event producer

In another terminal:

```bash
python src/producer/producer.py
```

The producer publishes order events to Kafka, while the consumer persists them into PostgreSQL.

---

## Milestones

### Milestone 1 — Event Ingestion

**Status: Completed**

- [x] Dockerized Kafka
- [x] Dockerized PostgreSQL
- [x] Kafka `order-events` topic
- [x] Historical event producer
- [x] Accelerated simulation mode
- [x] Realtime simulation mode
- [x] Kafka consumer
- [x] Consumer groups
- [x] Manual offset commits
- [x] PostgreSQL raw event storage
- [x] Idempotent database insertion
- [x] Database transaction rollback
- [x] Basic malformed event handling

### Milestone 2 — Transformation & Analytical Data Model

**Status: Planned**

This milestone will introduce the first analytical data model and transform raw order events into business-oriented datasets.

### Future Milestones

- [ ] Apache Airflow orchestration
- [ ] Data quality & automated testing
- [ ] Retry & Dead Letter Queue
- [ ] Monitoring & observability
- [ ] CI/CD
- [ ] Production-oriented improvements

---

## Current Status

**Milestone 1 completed and published to GitHub.**

The current implementation establishes the event ingestion foundation that will be extended in the next milestones.