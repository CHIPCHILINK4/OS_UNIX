#!/bin/sh -e

DATA_DIR="/data"
LOCK_FILE="$DATA_DIR/.lock"

CONTAINER_ID=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)
COUNTER=1

echo "Контейнер запущен. ID: $CONTAINER_ID" >&2

mkdir -p "$DATA_DIR"

while true; do
    CREATED_FILE=""
    set +e
    
    (
        flock -n 5 || exit 1
        
        i=1
        while true; do
            NAME=$(printf "%03d" "$i")
            FILE="$DATA_DIR/$NAME"

            if [ ! -e "$FILE" ]; then
                printf "%s %s\n" "$CONTAINER_ID" "$COUNTER" > "$FILE"
                echo "$FILE"
                break
            fi

            i=$((i + 1))
        done
    ) 5>"$LOCK_FILE" > /tmp/created_file.txt
    
    set -e 

    if [ $? -ne 0 ]; then
        sleep 0.1
        continue
    fi

    CREATED_FILE=$(cat /tmp/created_file.txt)

    sleep 1
    rm -f "$CREATED_FILE"
    sleep 1

    COUNTER=$((COUNTER + 1))
done