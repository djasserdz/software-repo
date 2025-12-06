# build the containers
docker compose \
--env-file .env \
-f docker-compose.yml \
build

# Run the containers
docker compose \
--env-file .env \
-f docker-compose.yml \
up -d $@     