#!/usr/bin/env bash

# Inventário básico de servidor Linux.
# Não instala pacotes nem altera serviços.

set -u

mostrar_ajuda() {
    cat <<'AJUDA'
Uso:
  ./collect-system-info.sh
  ./collect-system-info.sh --report
  ./collect-system-info.sh --help

Opções:
  --report      Salva um relatório privado em ~/infra-reports
  --help, -h    Mostra esta ajuda

Sem opções, apresenta o inventário no terminal.
O relatório pode conter IPs, nomes internos e identificadores.
AJUDA
}

executar() {
    local descricao="$1"
    shift

    printf '\n--- %s ---\n' "$descricao"

    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Não disponível: %s\n' "$1"
        return
    fi

    if ! "$@"; then
        printf 'Consulta falhou: %s\n' "$1"
    fi
}

coletar() {
    printf '========================================\n'
    printf ' INVENTÁRIO INICIAL — LINUX\n'
    printf '========================================\n'

    executar "Data e horário" date -Is

    printf '\n--- Sistema operacional ---\n'
    if [ -r /etc/os-release ]; then
        cat /etc/os-release
    else
        echo "Arquivo /etc/os-release não disponível."
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

    printf '\nInventário finalizado. Revise os resultados.\n'
}

if [ "$#" -eq 0 ]; then
    coletar
    exit 0
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

        if coletar > "$arquivo" 2>&1; then
            printf 'Relatório salvo em: %s\n' "$arquivo"
            echo "Revise informações sensíveis antes de compartilhar."
        else
            echo "Erro durante a gravação. Verifique o arquivo: $arquivo" >&2
            exit 1
        fi
        ;;
    *)
        echo "Erro: opção desconhecida: $1" >&2
        echo "Use --help para consultar as opções." >&2
        exit 2
        ;;
esac
