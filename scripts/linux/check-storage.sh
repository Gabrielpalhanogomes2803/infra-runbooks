#!/usr/bin/env bash

# Verifica espaço e inodes de um sistema de arquivos.
# Não remove arquivos nem altera o armazenamento.

set -u

mostrar_ajuda() {
    cat <<'AJUDA'
Uso:
  ./check-storage.sh [CAMINHO] [LIMITE]
  ./check-storage.sh --help

Exemplos:
  ./check-storage.sh
  ./check-storage.sh / 80
  ./check-storage.sh /var/log 90

Parâmetros:
  CAMINHO   Arquivo ou diretório no sistema de arquivos.
            Padrão: /
  LIMITE    Percentual inteiro de alerta, de 1 a 100.
            Padrão: 80

Códigos de saída:
  0    Espaço e inodes abaixo do limite
  1    Limite atingido para espaço ou inodes
  2    Argumento inválido ou erro na consulta

O script apenas consulta informações.
AJUDA
}

if [ "$#" -eq 1 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ]; }; then
    mostrar_ajuda
    exit 0
fi

if [ "$#" -gt 2 ]; then
    echo "Erro: argumentos demais. Use --help." >&2
    exit 2
fi

caminho="${1:-/}"
limite="${2:-80}"

if [ ! -e "$caminho" ]; then
    echo "Erro: caminho não existe: $caminho" >&2
    exit 2
fi

if [[ ! "$limite" =~ ^[0-9]{1,3}$ ]] ||
   [ "$((10#$limite))" -lt 1 ] ||
   [ "$((10#$limite))" -gt 100 ]; then
    echo "Erro: limite deve ser um número inteiro de 1 a 100." >&2
    exit 2
fi

limite=$((10#$limite))

if ! command -v df >/dev/null 2>&1; then
    echo "Erro: comando df não encontrado." >&2
    exit 2
fi

# LC_ALL=C mantém a saída do df consistente para interpretação.
if ! espaco=$(LC_ALL=C df -P -- "$caminho"); then
    echo "Erro ao consultar espaço em: $caminho" >&2
    exit 2
fi

if ! inodes=$(LC_ALL=C df -Pi -- "$caminho"); then
    echo "Erro ao consultar inodes em: $caminho" >&2
    exit 2
fi

# Na saída POSIX do df, o percentual fica na penúltima coluna.
uso_espaco=$(printf '%s\n' "$espaco" | awk 'NR > 1 {print $(NF-1); exit}')
uso_inodes=$(printf '%s\n' "$inodes" | awk 'NR > 1 {print $(NF-1); exit}')

if [[ ! "$uso_espaco" =~ ^[0-9]+%$ ]] ||
   [[ ! "$uso_inodes" =~ ^[0-9]+%$ ]]; then
    echo "Erro: não foi possível interpretar a saída do df." >&2
    echo "Confira se esse sistema de arquivos informa inodes." >&2
    exit 2
fi

uso_espaco="${uso_espaco%%%}"
uso_inodes="${uso_inodes%%%}"

printf '\n========================================\n'
printf ' VERIFICAÇÃO DE ARMAZENAMENTO\n'
printf '========================================\n'
printf 'Caminho: %s\n' "$caminho"
printf 'Limite de alerta: %s%%\n\n' "$limite"

printf '%s\n\n' "$espaco"
printf '%s\n\n' "$inodes"

alerta=0

if [ "$uso_espaco" -ge "$limite" ]; then
    printf 'ALERTA: espaço utilizado em %s%%.\n' "$uso_espaco"
    alerta=1
else
    printf 'OK: espaço utilizado em %s%%.\n' "$uso_espaco"
fi

if [ "$uso_inodes" -ge "$limite" ]; then
    printf 'ALERTA: inodes utilizados em %s%%.\n' "$uso_inodes"
    alerta=1
else
    printf 'OK: inodes utilizados em %s%%.\n' "$uso_inodes"
fi

exit "$alerta"
