# LeoneEMR

LeoneEMR is the OpenMRS configuration for Sierra Leone, combining the former `openmrs-config-pihemr` and `openmrs-config-pihsl` repositories into a single, unified configuration.

## Prerequisites

- **Java 8+** (OpenJDK or Oracle JDK)
- **Maven 3.x**
- **Docker** (for running MySQL locally)
- **Git**
- ~4GB free RAM for the OpenMRS server

## Quick Start (Linux)

### 1. Install Prerequisites

```bash
# Java 8
sudo apt update && sudo apt install -y openjdk-8-jdk maven docker.io

# Start Docker
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### 2. Start the Database

```bash
docker run -d --name openmrs-db \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=sierraLeone \
  -p 3308:3306 \
  mysql:8.0
```

### 3. Clone and Build

```bash
git clone https://github.com/lolleh/LeoneEMR.git
cd LeoneEMR

# Compile and deploy configuration to the SDK server
mvn clean compile -pl '!content' -DserverId=sierraLeone
```

### 4. Run the Server

```bash
mvn openmrs-sdk:run -DserverId=sierraLeone
```

The first start will take several minutes as it downloads modules and runs database migrations.

### 5. Access the Application

Open your browser and go to:

```
http://localhost:8080/openmrs/spa
```

**Default login credentials:**
- Username: `admin`
- Password: `Admin123`

---

## Quick Start (Windows)

### 1. Install Prerequisites

- **Java 8**: Download and install from [Adoptium](https://adoptium.net/) (Temurin 8 LTS)
- **Maven**: Download from [maven.apache.org](https://maven.apache.org/download.cgi) and add to PATH
- **Docker Desktop**: Download and install from [docker.com](https://www.docker.com/products/docker-desktop/)
- **Git**: Download from [git-scm.com](https://git-scm.com/)

### 2. Start the Database

Open PowerShell or Command Prompt and run:

```powershell
docker run -d --name openmrs-db -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=sierraLeone -p 3308:3306 mysql:8.0
```

### 3. Clone and Build

```powershell
git clone https://github.com/lolleh/LeoneEMR.git
cd LeoneEMR

# Compile and deploy configuration
mvn clean compile -pl '!content' -DserverId=sierraLeone
```

### 4. Run the Server

```powershell
mvn openmrs-sdk:run -DserverId=sierraLeone
```

### 5. Access the Application

Open your browser to:

```
http://localhost:8080/openmrs/spa
```

**Default login credentials:**
- Username: `admin`
- Password: `Admin123`

---

## Common Commands

| Command | Description |
|---------|-------------|
| `./install.sh [serverId]` | Build and deploy to a local SDK server |
| `./watch.sh [serverId]` | Watch for file changes and auto-deploy |
| `./pull.sh` | Pull latest changes from Git |
| `mvn clean compile` | Generate configs into `target/` |
| `mvn clean package` | Build a deployable zip package |
| `mvn clean compile -DserverId=<name>` | Compile and copy config to `~/openmrs/<name>/configuration` |
| `docker start openmrs-db` | Start the MySQL database container |
| `docker stop openmrs-db` | Stop the MySQL database container |

## Project Structure

```
LeoneEMR/
├── pom.xml                     # Root POM
├── constants.yml               # Shared UUIDs and constants
├── configuration/              # Configuration files (concepts, forms, reports, etc.)
│   ├── pih/                    # PIH-specific configs, forms, and scripts
│   ├── frontend/               # OpenMRS 3.x SPA frontend config
│   └── ocl/                    # Open Concept Lab concept dictionaries
├── content/                    # Content packaging module
├── install.sh                  # Build and deploy script
├── watch.sh                    # Watch and auto-deploy script
└── pull.sh                     # Git pull script
```

## Troubleshooting

### Database connection fails
Ensure the MySQL Docker container is running:
```bash
docker ps --filter name=openmrs-db
docker start openmrs-db   # if stopped
```

### Port 8080 already in use
Kill existing processes or change the port:
```bash
# Find and kill existing Java processes on port 8080
kill $(lsof -ti:8080)

# Or use a different port
mvn openmrs-sdk:run -DserverId=sierraLeone -Dport=8081
```

### Frontend shows blank page
The OpenMRS SPA frontend takes a moment to load after the server starts. Wait 1-2 minutes and refresh.

## License

Mozilla Public License 2.0 with Healthcare Disclaimer
