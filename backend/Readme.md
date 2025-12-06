# Solveit 3.0

SolveIt v3.0 is an advanced problem-solving platform designed to facilitate collaboration and innovation. This version introduces significant improvements in performance, security, and user experience.



## How to run Locally

### Create .env File
Create a `.env` file in the root directory, based on the provided `.env.example`, so you can only create a copy of it and rename it to `.env`.


### Run Docker 
if you Have Alredy build the containers then you can run the following command in the same directory that contains the `docker-compose.yml` file to start the application:

```bash
docker compose \
--env-file .env \
-f docker-compose.yml \
up -d
```
else you can build and run the containers using the following command:

```bash
./scripts/build_local.sh
```

The backend API will be available at `http://localhost:8000`
and the docs at `http://localhost:8000/docs`



## 📋 Code Quality and Linting

**⚠️ IMPORTANT: Before committing your code, always run the following commands:**

### Format Code with Ruff

```bash
# Format all Python files
ruff format 

# Format specific directory
ruff format backend/src
```

### Check and Fix Issues with Ruff

```bash
# Check for linting issues and auto-fix
ruff check --fix .

# Check specific directory
ruff check --fix backend/src

# Check without fixing (dry run)
ruff check .
```
## Tip: the new lib installed

whene you install any new lib you must add it to the `requirements.txt` 
