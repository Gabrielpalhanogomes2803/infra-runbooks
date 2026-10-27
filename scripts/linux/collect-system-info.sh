#!/usr/bin/env bash

# Inventário básico de servidor Linux.
# Consulta informações sem instalar pacotes ou alterar serviços.

set -u

coleta_parcial=0

mostrar_ajuda() {
    cat <<'AJUDA'
Uso:
  ./collect-system-info.sh
  ./collect-system-info.sh --report
  ./collect-system-info.sh --help

Opções:
  --report      Salva relatório privado em ~/infra-reports
  --help, -h    Mostra esta ajuda

Códigos de saída:
  0    Coleta completa ou ajuda exibida
  1    Erro ao criar ou gravar o relatório
  2    Argumento inválido
  3    Coleta parcial

O relatório pode conter IPs, nomes internos e identificadores.
Revise o conteúdo antes de compartilhar.
AJUDA
}

executar() {
    local descricao="$1"
    shift

    printf '\n--- %s ---\n' "$descricao"

    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Não disponível: %s\n' "$1"
        coleta_parcial=1
        return
    fi

    if ! "$@"; then
        printf 'Consulta falhou: %s\n' "$1"
        coleta_parcial=1
    fi
}

coletar() {
    printf '========================================\n'
    printf ' INVENTÁRIO INICIAL — LINUX\n'
    printf '========================================\n'

    executar "Data e horário" date -Is

    printf '\n--- Sistema operacional ---\n'

    if [ -r /etc/os-release ]; then
        if ! cat /etc/os-release; then
            echo "Falha ao ler /etc/os-release."
            coleta_parcial=1
        fi
    else
        echo "Arquivo /etc/os-release não disponível."
        coleta_parcial=1
    fi

    executar "Kernel" uname -r
    executar "Identificação do host" hostnamectl
    executar "Tempo de atividade" uptime
    executar "CPU" lscpu
    executar "Memória e swap" free -h
    executar "Discos" lsblk -f
    executar "Sistemas de arquivos" df -hT
    executar "Interfaces de rede" ip -br address
    executar "Rotas IPv4" ip route
    executar "Horário e sincronização" timedatectl
    executar "Unidades systemd com falha" systemctl --failed --no-pager

    if [ "$coleta_parcial" -eq 1 ]; then
        printf '\nInventário parcial: revise as consultas indicadas.\n'
        return 3
    fi

    printf '\nInventário finalizado. Revise os resultados.\n'
    return 0
}

if [ "$#" -eq 0 ]; then
    coletar
    exit $?
fi

if [ "$#" -ne 1 ]; then
    echo "Erro: informe somente uma opção." >&2
    exit 2
fi

case "$1" in
    --help|-h)
        mostrar_ajuda
        ;;

    --report)
        diretorio="$HOME/infra-reports"

        if [ ! -d "$diretorio" ]; then
            echo "Erro: diretório não encontrado: $diretorio" >&2
            echo "Crie o diretório privado antes de continuar." >&2
            exit 1
        fi

        umask 077

        arquivo=$(mktemp "$diretorio/inventario-$(date +%Y%m%d-%H%M%S)-XXXXXX.txt") || {
            echo "Erro: não foi possível criar o relatório." >&2
            exit 1
        }

        coletar 2>&1 | cat > "$arquivo"
        status=("${PIPESTATUS[@]}")

        if [ "${status[1]}" -ne 0 ]; then
            echo "Erro ao gravar o relatório: $arquivo" >&2
            echo "O arquivo pode estar incompleto." >&2
            exit 1
        fi

        if [ "${status[0]}" -ne 0 ] && [ "${status[0]}" -ne 3 ]; then
            echo "Erro durante a coleta. Arquivo: $arquivo" >&2
            exit 1
        fi

        printf 'Relatório salvo em: %s\n' "$arquivo"
        echo "Revise informações sensíveis antes de compartilhar."

        if [ "${status[0]}" -eq 3 ]; then
            echo "A coleta foi parcial. Confira o relatório." >&2
            exit 3
        fi

        exit 0
        ;;

    *)
        echo "Erro: opção desconhecida: $1" >&2
        echo "Use --help para consultar as opções." >&2
        exit 2
        ;;
esac
