#!/usr/bin/env bash
# Create the orders topic and produce demo events into YOUR Kafka.
# Adjust BOOTSTRAP / TOPIC to your environment. Two variants below — pick one.
set -euo pipefail

TOPIC="${TOPIC:-orders-v2}"
BOOTSTRAP="${BOOTSTRAP:-localhost:9092}"
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "Topic=$TOPIC  Bootstrap=$BOOTSTRAP"

# ---- Variant A: Kafka CLI tools are on your PATH -------------------------
if command -v kafka-console-producer >/dev/null 2>&1; then
  kafka-topics --bootstrap-server "$BOOTSTRAP" --create --topic "$TOPIC" \
    --partitions 3 --replication-factor 1 2>/dev/null || echo "(topic exists)"
  python3 "$HERE/gen_orders.py" | kafka-console-producer --bootstrap-server "$BOOTSTRAP" --topic "$TOPIC"
  echo "Produced 30 events to $TOPIC."
  exit 0
fi

# ---- Variant B: Kafka runs in a docker container -------------------------
# Set KAFKA_CONTAINER to your broker container name, e.g.:
#   KAFKA_CONTAINER=my-kafka BOOTSTRAP=localhost:9092 ./load_kafka.sh
if [ -n "${KAFKA_CONTAINER:-}" ]; then
  docker exec "$KAFKA_CONTAINER" kafka-topics --bootstrap-server "$BOOTSTRAP" --create \
    --topic "$TOPIC" --partitions 3 --replication-factor 1 2>/dev/null || echo "(topic exists)"
  python3 "$HERE/gen_orders.py" | docker exec -i "$KAFKA_CONTAINER" \
    kafka-console-producer --bootstrap-server "$BOOTSTRAP" --topic "$TOPIC"
  echo "Produced 30 events to $TOPIC (via container $KAFKA_CONTAINER)."
  exit 0
fi

echo "No kafka CLI on PATH and KAFKA_CONTAINER not set."
echo "Pipe the generator into whatever producer you use, e.g.:"
echo "  python3 $HERE/gen_orders.py | <your-kafka-producer> --topic $TOPIC"

# ---- Live 'wow' order (run during the multi-hop round) -------------------
# python3 gen_orders.py --wow | <your-producer> --topic orders-v2
