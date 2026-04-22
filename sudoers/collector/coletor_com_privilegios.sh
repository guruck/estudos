#!/bin/sh

# Identificação do Host
HOSTNAME=$(hostname)
OS_NAME=$(uname -s)

# Função de Data Compatível (POSIX)
convert_days_to_iso() {
    days=$1
    if [ -z "$days" ] || [ "$days" = "0" ] || [ "$days" = "99999" ]; then
        echo "9999-12-31"; return
    fi
    seconds=$((days * 86400))
    # Detecta se é GNU date ou BSD date
    if date --version >/dev/null 2>&1; then
        date -u -d "@$seconds" +%Y-%m-%d 2>/dev/null || echo "9999-12-31"
    else
        date -u -r "$seconds" +%Y-%m-%d 2>/dev/null || echo "9999-12-31"
    fi
}

# 1. Mapeia Sudoers
SUDO_RULES=$(grep -shE '^[^# ]' /etc/sudoers /etc/sudoers.d/* 2>/dev/null)
SUDO_GROUPS=$(echo "$SUDO_RULES" | grep '^%' | cut -d' ' -f1 | tr -d '%' || echo "")

# 2. Fonte de Usuários
if command -v getent >/dev/null 2>&1; then
    USERS_SOURCE=$(getent passwd)
else
    USERS_SOURCE=$(cat /etc/passwd)
fi

# 3. Processamento linha por linha (Compatível com qualquer Shell)
echo "$USERS_SOURCE" | while IFS=: read -r user pass uid gid info home shell; do

    # Valida Fonte
    if grep -q "^${user}:" /etc/passwd 2>/dev/null; then fonte="LOCAL"; else fonte="REDE"; fi

    # Shadow Data
    if command -v getent >/dev/null 2>&1; then
        shadow_line=$(getent shadow "$user" 2>/dev/null)
    else
        shadow_line=$(grep "^${user}:" /etc/shadow 2>/dev/null)
    fi

    d_alt=$(echo "$shadow_line" | cut -d: -f3)
    d_exp=$(echo "$shadow_line" | cut -d: -f8)

    dt_alteracao=$(convert_days_to_iso "$d_alt")
    dt_expiracao=$(convert_days_to_iso "$d_exp")

    # Grupos (Lista separada por vírgula)
    user_groups_list=$(id -Gn "$user" 2>/dev/null | tr ' ' ',')

    # --- Lógica de Privilégio Definitiva ---
    # Lógica de Privilégio
    privs=""

    if [ "$uid" = "0" ]; then
        privs="SIM_ROOT"
    fi

    # Busca o usuário direto no sudoers (ignora espaços/tabs)
    if echo "$SUDO_RULES" | grep -qE "^${user}[[:space:]]+"; then
        [ -n "$privs" ] && privs="$privs,"
        privs="${privs}DIRETO"
    fi

    # Loop de grupos: verifica se o grupo do usuário está no sudoers (com %)
    for g in $(echo "$user_groups_list" | tr ',' ' '); do
        # Procura por "%nome_do_grupo" no início da linha do sudoers
        if echo "$SUDO_RULES" | grep -qE "^%${g}[[:space:]]+"; then
            [ -n "$privs" ] && privs="$privs,"
            privs="${privs}GRUPO($g)"
        fi
    done

    [ -z "$privs" ] && has_sudo="NAO" || has_sudo="$privs"

    echo "${HOSTNAME}|${OS_NAME}|${user}|${uid}|${fonte}|${shell}|${dt_alteracao}|${dt_expiracao}|${user_groups_list}|${has_sudo}"
done
