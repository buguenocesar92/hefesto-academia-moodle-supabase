#!/usr/bin/env bash
# Validador de compose contra el contrato de Coolify MVP Hefesto.
# Salida 0 = cumple; != 0 = lista los incumplimientos, uno por línea.
#
# Aplicación del contrato común del plan (rama coolify):
#   - Punto 1: en servicios sin profiles no puede haber powershell...
#     ports, container_name, privileged, cap_add, devices, network_mode: host,
#     pid/ipc: host, security_opt con unconfined, binds a docker.sock,
#     ni binds fuera del repo.
#   - Punto 2: nada de 'name:' fijo en raíz, en volúmenes ni en redes.
#   - Punto 3 (supabase-pg): el render contiene mvp_prueba y disable
#     (DB_NAME y DB_SSLMODE parametrizados).
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SELF_DIR/.." && pwd)"

# Inventario del repo: un único compose, base_dir raíz, bd supabase-pg.
COMPOSE_FILE="$REPO_ROOT/compose.yaml"
APP_KIND="supabase-pg"
BASE_DIR="$REPO_ROOT"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "coolify-check: no existe $COMPOSE_FILE" >&2
    exit 1
fi

TMP="${TMPDIR:-/tmp}/coolify-check.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# Extraer los nombres de variable que aparecen en el compose como ${VAR},
# ${VAR:-default} o ${VAR:?mensaje}. Cubre todos los modificadores de bash.
extract_vars() {
    sed -nE 's/.*\$\{([A-Z_][A-Z0-9_]*)(:[-=?[#%][^}]*)?\}.*/\1/p' "$1" | sort -u
}

# Generar un .env temporal con valores ficticios no secretos.
make_env() {
    local out="$1"
    : > "$out"
    local v
    while IFS= read -r v; do
        [ -z "$v" ] && continue
        case "$v" in
            *HOST*|*URL*|*DOMAIN*) printf '%s=https://ejemplo.invalid\n' "$v" >> "$out" ;;
            *) printf '%s=x1234567890abcdefghij\n' "$v" >> "$out" ;;
        esac
    done < <(extract_vars "$COMPOSE_FILE")
    if [ "$APP_KIND" = "supabase-pg" ]; then
        printf 'DB_SSLMODE=disable\n' >> "$out"
        printf 'DB_NAME=mvp_prueba\n' >> "$out"
    fi
}

make_env "$TMP/env"
RENDER="$TMP/rendered.json"

if ! docker compose --project-name coolify-check --project-directory "$BASE_DIR" -f "$COMPOSE_FILE" --env-file "$TMP/env" config --format json > "$RENDER" 2>"$TMP/err"; then
    echo "coolify-check: no se pudo renderizar $(basename "$COMPOSE_FILE"):" >&2
    sed 's/^/  /' "$TMP/err" >&2
    exit 2
fi

FAILED=0
note() { echo "coolify-check: $1" >&2; FAILED=1; }

# --- Punto 2 del contrato: sin name: fijo en el YAML ---
# Coolify pone su propio project name y por eso no debe haber 'name:' a nivel
# raíz en el YAML. Para volúmenes y redes, docker compose deriva
# "<project>_<key>" cuando el YAML no lo fija; eso es válido.

PROJECT_NAME="coolify-check"

if awk 'BEGIN{found=0} /^name:[[:space:]]/{found=1; exit 0} END{exit !found}' "$COMPOSE_FILE"; then
    note "regla2: raiz: 'name:' fijo en el YAML; Coolify pone el nombre del proyecto"
fi

while IFS= read -r v; do
    [ -z "$v" ] && continue
    rendered_name=$(jq -r ".volumes.\"$v\".name // empty" "$RENDER" 2>/dev/null || true)
    if [ -z "$rendered_name" ]; then
        continue
    fi
    if [ "$rendered_name" != "${PROJECT_NAME}_${v}" ]; then
        note "regla2: volumen: '$v' tiene 'name:' fijo ($rendered_name); Coolify pone el nombre del volumen"
    fi
done < <(jq -r '.volumes // {} | keys[]' "$RENDER" 2>/dev/null || true)

while IFS= read -r n; do
    [ -z "$n" ] && continue
    rendered_name=$(jq -r ".networks.\"$n\".name // empty" "$RENDER" 2>/dev/null || true)
    if [ -z "$rendered_name" ]; then
        continue
    fi
    if [ "$rendered_name" != "${PROJECT_NAME}_${n}" ]; then
        note "regla2: red: '$n' tiene 'name:' fijo ($rendered_name)"
    fi
done < <(jq -r '.networks // {} | keys[]' "$RENDER" 2>/dev/null || true)

# --- Punto 1 del contrato: servicios sin profiles, sin escapes de Traefik ---

while IFS= read -r svc; do
    [ -z "$svc" ] && continue
    if jq -e ".services.\"$svc\" | has(\"profiles\")" "$RENDER" >/dev/null 2>&1; then
        continue  # los servicios con profiles quedan exentos
    fi

    if jq -e ".services.\"$svc\" | has(\"ports\")" "$RENDER" >/dev/null 2>&1; then
        note "regla1: ports: $svc: expone 'ports:' (Traefik debe enrutar el dominio)"
    fi
    if jq -e ".services.\"$svc\" | has(\"container_name\")" "$RENDER" >/dev/null 2>&1; then
        note "regla1: container_name: $svc: 'container_name:' fijo"
    fi
    if [ "$(jq -r ".services.\"$svc\".privileged // false" "$RENDER")" = "true" ]; then
        note "regla1: privileged: $svc: privileged=true"
    fi
    if jq -e ".services.\"$svc\" | has(\"cap_add\")" "$RENDER" >/dev/null 2>&1; then
        note "regla1: cap_add: $svc: presente"
    fi
    if jq -e ".services.\"$svc\" | has(\"devices\")" "$RENDER" >/dev/null 2>&1; then
        note "regla1: devices: $svc: presente"
    fi
    if [ "$(jq -r ".services.\"$svc\".network_mode // empty" "$RENDER")" = "host" ]; then
        note "regla1: network_mode: $svc: host"
    fi
    for k in pid ipc; do
        if [ "$(jq -r ".services.\"$svc\".$k // empty" "$RENDER")" = "host" ]; then
            note "regla1: $k: $svc: host"
        fi
    done
    if jq -e ".services.\"$svc\".security_opt | type==\"array\" and any(. == \"unconfined\")" "$RENDER" >/dev/null 2>&1; then
        note "regla1: security_opt: $svc: unconfined"
    fi

    # Binds prohibidos: docker.sock y absolutos fuera del repo.
    while IFS=$'\t' read -r bind_src bind_type; do
        [ -z "$bind_src" ] && continue
        case "$bind_type" in
            bind|"") ;;
            *) continue ;;
        esac
        case "$bind_src" in
            *docker.sock) note "regla1: docker_sock: $svc: bind a docker.sock" ;;
        esac
        case "$bind_src" in
            /*)
                # Anclar el sufijo: REPO_ROOT o REPO_ROOT/...; idem para /etc/ssl/certs/custom.
                if [[ "$bind_src" != "$REPO_ROOT" && "$bind_src" != "$REPO_ROOT"/* \
                    && "$bind_src" != "/etc/ssl/certs/custom" && "$bind_src" != "/etc/ssl/certs/custom/"* ]]; then
                    note "regla1: bind_fuera_repo: $svc: $bind_src"
                fi
                ;;
        esac
    done < <(jq -r ".services.\"$svc\".volumes // [] | .[] | select((.type // \"bind\") == \"bind\") | [.source // empty, .type // \"bind\"] | @tsv" "$RENDER" 2>/dev/null || true)
done < <(jq -r '.services | keys[]' "$RENDER" 2>/dev/null || true)

# --- Punto 3 (supabase-pg): DB_NAME y DB_SSLMODE llegan al render ---

if [ "$APP_KIND" = "supabase-pg" ]; then
    if ! grep -q 'mvp_prueba' "$RENDER"; then
        note "supabase_pg: db_name: render no contiene 'mvp_prueba' (DB_NAME no llega al render)"
    fi
    if ! grep -q '"disable"' "$RENDER"; then
        note "supabase_pg: sslmode: render no contiene 'disable' (DB_SSLMODE=disable no llega al render)"
    fi
fi

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi
echo "OK: $(basename "$COMPOSE_FILE") cumple el contrato de Coolify MVP Hefesto."
exit 0