#!/usr/bin/env bash
# install-prereqs.sh — installs the PHU360 build prerequisites:
#   Docker, Maven 3.9+, and a JDK 17+
#
# Supports Debian/Ubuntu (apt) and macOS (Homebrew). Detects what is already
# installed and only installs the missing pieces. Idempotent; safe to re-run.
#
#   scripts/install-prereqs.sh       # with confirmation prompts
#   scripts/install-prereqs.sh -y    # assume yes
set -euo pipefail

MAVEN_VERSION="${MAVEN_VERSION:-3.9.9}"
MAVEN_DLCDN_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_CENTRAL_URL="https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${MAVEN_VERSION}/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

ASSUME_YES=false
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && ASSUME_YES=true

say()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
warn() { printf '\033[0;33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[0;31m%s\033[0m\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  if [[ "$ASSUME_YES" == "true" ]]; then return 0; fi
  printf '%s [Y/n] ' "$1"
  read -r reply
  [[ "${reply:-y}" =~ ^[Yy]$ ]]
}

java_major() {
  local v
  v="$(java -version 2>&1 | head -1)"
  if [[ "$v" =~ \"1\.([0-9]+) ]]; then      echo "${BASH_REMATCH[1]}"
  elif [[ "$v" =~ \"([0-9]+)\. ]]; then      echo "${BASH_REMATCH[1]}"
  elif [[ "$v" =~ ([0-9]+)\. ]]; then        echo "${BASH_REMATCH[1]}"
  else echo 0; fi
}

mvn_ver() { mvn -version 2>/dev/null | sed -n 's/.*Apache Maven \([0-9.]*\).*/\1/p' | head -1; }

mvn_at_least_390() {
  local v="$1" major minor
  [[ "$v" =~ ^([0-9]+)\.([0-9]+) ]] || return 1
  major="${BASH_REMATCH[1]}"; minor="${BASH_REMATCH[2]}"
  (( major > 3 )) || { (( major == 3 )) && (( minor >= 9 )); }
}

# ---------------------------------------------------------------------------
say "==> Checking what is already installed"
JDK_OK=false
if have java; then
  J="$(java_major)"
  if (( J >= 17 )); then say "    OK  JDK already present (major $J)."; JDK_OK=true
  else warn "    JDK too old (major $J < 17); will install a newer one."
  fi
else
  warn "    JDK not found; will install one."
fi

MVN_OK=false
if have mvn; then
  M="$(mvn_ver)"
  if mvn_at_least_390 "$M"; then say "    OK  Maven already present ($M)."; MVN_OK=true
  else warn "    Maven too old ($M < 3.9); will install ${MAVEN_VERSION}."
  fi
else
  warn "    Maven not found; will install ${MAVEN_VERSION}."
fi

DOCKER_OK=false
if have docker && docker info >/dev/null 2>&1; then
  say "    OK  Docker daemon is running ($(docker --version 2>/dev/null | sed 's/Docker version //'))."
  DOCKER_OK=true
elif have docker; then
  warn "    Docker CLI present but the daemon is not running."
else
  warn "    Docker not found; will install it."
fi

if [[ "$JDK_OK" == "true" && "$MVN_OK" == "true" && "$DOCKER_OK" == "true" ]]; then
  say "==> All prerequisites already satisfied. Nothing to do."
  exit 0
fi

confirm "Install the missing pieces? (may ask for your password)" || { say "Aborted."; exit 1; }

SUDO=""
if (( EUID != 0 )); then
  have sudo || die "run as root or install sudo"
  SUDO="sudo"
fi

# ---------------------------------------------------------------------------
if have apt-get; then
  # ---- JDK 17+ ----
  if [[ "$JDK_OK" != "true" ]]; then
    say "==> Installing a JDK ($SUDO apt-get)"
    $SUDO apt-get update -y
    for pkg in openjdk-17-jdk openjdk-21-jdk openjdk-25-jdk; do
      if apt-cache show "$pkg" >/dev/null 2>&1; then
        $SUDO apt-get install -y "$pkg"
        JDK_OK=true
        break
      fi
    done
    [[ "$JDK_OK" == "true" ]] || warn "    Could not install a JDK package automatically; install a JDK 17+ manually."
  fi

  # ---- Maven 3.9+ ----
  if [[ "$MVN_OK" != "true" ]]; then
    say "==> Installing Maven ${MAVEN_VERSION} into /opt/maven"
    tmp="$(mktemp)"
    if ! (curl -fsSL "$MAVEN_DLCDN_URL" -o "$tmp" 2>/dev/null || curl -fsSL "$MAVEN_CENTRAL_URL" -o "$tmp"); then
      rm -f "$tmp"
      die "could not download Maven; check network access"
    fi
    $SUDO mkdir -p /opt/maven
    $SUDO tar -xzf "$tmp" -C /opt/maven --strip-components=1
    rm -f "$tmp"
    $SUDO ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn
    MVN_OK=true
  fi

  # ---- Docker ----
  if [[ "$DOCKER_OK" != "true" ]]; then
    say "==> Installing Docker (docker.io) and starting the daemon"
    $SUDO apt-get install -y docker.io
    $SUDO systemctl enable --now docker 2>/dev/null || $SUDO service docker start 2>/dev/null || true
    if (( EUID != 0 )); then
      $SUDO usermod -aG docker "${SUDO_USER:-$USER}"
      warn "    Added ${SUDO_USER:-$USER} to the 'docker' group — log out/in (or 'newgrp docker') to use docker without sudo."
    fi
    DOCKER_OK=true
  fi

# ---------------------------------------------------------------------------
elif have brew; then
  [[ "$JDK_OK" != "true" ]] && { say "==> Installing a JDK (brew)"; brew install openjdk@21; }
  [[ "$MVN_OK" != "true" ]] && { say "==> Installing Maven (brew)"; brew install maven; }
  if [[ "$DOCKER_OK" != "true" ]]; then
    say "==> Installing Docker Desktop (brew cask)"
    brew install --cask docker
    warn "    Open Docker Desktop once and start it, then re-run this script."
  fi

else
  die "unsupported platform — install Docker, Maven 3.9+ and a JDK 17+ manually"
fi

# ---------------------------------------------------------------------------
say "==> Verifying"
have java && java -version 2>&1 | head -1 || true
have mvn  && mvn -version 2>&1 | head -1 || true
have docker && docker --version || warn "    docker CLI not on PATH yet (re-login for the group change)"
have docker && (docker compose version >/dev/null 2>&1 || docker-compose --version >/dev/null 2>&1) \
  && echo "    $(docker compose version 2>/dev/null || docker-compose --version)" || true

J2="$(have java && java_major || echo 0)"
M2="$(have mvn && mvn_ver || echo 0)"
if (( J2 >= 17 )) && mvn_at_least_390 "$M2"; then
  say "==> Prerequisites ready: JDK $J2, Maven $M2, Docker $(docker --version 2>/dev/null | sed 's/.*version //' || echo '?')"
  say "    Next: scripts/seed-distro-maven-repo.sh && scripts/build-distro.sh && docker compose up -d --build"
else
  warn "==> Some prerequisites are not detected yet — see the messages above."
fi