#!/usr/bin/env bash

# Consulta o estado de serviços systemd.
# Não inicia, para ou reinicia serviços.

set -u

mostrar_ajuda() {
    cat <<'AJUDA'
Uso:
  ./check-services.sh SERVICO [SERVICO...]
  ./check-services.sh --help

Exemplos:
  ./check-services.sh nginx.service
  ./check-services.sh nginx.service docker.service

Informe um ou mais nomes de unidades .service.

Códigos de saída:
  0    Todos os serviços consultados estão ativos
  1    Pelo menos um serviço está inativo ou em falha
  2    Argumento inválido ou erro na consulta
  3    Pelo menos uma unidade não foi encontrada

Se houver mais de uma condição, erro de consulta tem prioridade,
seguido de unidade não encontrada e serviço inativo/em falha.
AJUDA
}

if [ "$#" -eq 1 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ]; }; then
    mostrar_ajuda
    exit 0
fi

if [ "$#" -eq 0 ]; then
    echo "Erro: informe pelo menos um serviço. Use --help." >&2
    exit 2
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Erro: systemctl não encontrado." >&2
    exit 2
fi

# Confirma que o gerenciador systemd está acessível.
if ! systemctl show --property=Version --value >/dev/null 2>&1; then
    echo "Erro: não foi possível consultar o systemd." >&2
    exit 2
fi

tem_inativo=0
tem_ausente=0
tem_erro=0

for servico in "$@"; do
    # Aceita apenas nomes simples de unidades de serviço.
    if [[ ! "$servico" =~ ^[a-zA-Z0-9_.@:-]+\.service$ ]]; then
        printf 'Argumento inválido: %s\n' "$servico" >&2
        tem_erro=1
        continue
    fi

    if ! dados=$(systemctl show "$servico" \
        --property=LoadState \
        --property=ActiveState \
        --property=SubState 2>/dev/null); then
        printf 'ERRO: não foi possível consultar %s\n' "$servico" >&2
        tem_erro=1
        continue
    fi

    carga=""
    estado=""
    subestado=""

    while IFS='=' read -r chave valor; do
        case "$chave" in
            LoadState)   carga="$valor" ;;
            ActiveState) estado="$valor" ;;
            SubState)    subestado="$valor" ;;
        esac
    done <<< "$dados"

    if [ "$carga" = "not-found" ]; then
        printf 'AUSENTE: %s não encontrado.\n' "$servico"
        tem_ausente=1
    elif [ "$carga" != "loaded" ] || [ -z "$estado" ]; then
        printf 'ERRO: %s não pôde ser carregado (LoadState=%s).\n' \
            "$servico" "${carga:-desconhecido}" >&2
        tem_erro=1
    elif [ "$estado" = "active" ]; then
        printf 'ATIVO: %s (subestado: %s)\n' \
            "$servico" "${subestado:-desconhecido}"
    else
        printf 'NÃO ATIVO: %s (estado: %s; subestado: %s)\n' \
            "$servico" "$estado" "${subestado:-desconhecido}"
        tem_inativo=1
    fi
done

if [ "$tem_erro" -eq 1 ]; then
    exit 2
elif [ "$tem_ausente" -eq 1 ]; then
    exit 3
elif [ "$tem_inativo" -eq 1 ]; then
    exit 1
fi

exit 0
