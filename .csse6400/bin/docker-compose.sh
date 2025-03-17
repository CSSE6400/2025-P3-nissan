#!/bin/bash
#
# Check that the health endpoint is returning 200 using docker-compose
docker-compose build
docker-compose up -d
error=$?
if [[ $error -ne 0 ]]; then
    echo "Failed to run docker-compose up"
    docker-compose logs
    exit 1
fi

# Wait for the database to be ready
echo "Waiting for database to be ready..."
for i in {1..30}; do
    if docker-compose exec database pg_isready -U administrator -d todo > /dev/null 2>&1; then
        echo "Database is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Database failed to start within 30 seconds"
        docker-compose logs database
        docker-compose down
        exit 1
    fi
    sleep 1
done

# Wait for the application to be ready
echo "Waiting for application to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:6400/api/v1/health > /dev/null; then
        echo "Application is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Application failed to start within 30 seconds"
        docker-compose logs app
        docker-compose down
        exit 1
    fi
    sleep 1
done

# Check that the health endpoint is returning 200
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:6400/api/v1/health)
if [[ $response != "200" ]]; then
    echo "Failed to get 200 from health endpoint. Got status code: $response"
    docker-compose logs app
    docker-compose down
    exit 1
fi

echo "Health check passed!"
docker-compose down

