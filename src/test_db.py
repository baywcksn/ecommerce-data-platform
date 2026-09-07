import psycopg

conn = psycopg.connect(
    "host=localhost port=5433 dbname=ecommerce user=ecommerce password=ecommerce"
)

print("PostgreSQL connection OK")

conn.close()
