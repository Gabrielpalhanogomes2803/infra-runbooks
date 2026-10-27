#!/usr/bin/env bash
# Diagnóstico pontual de DNS, rota IPv4, TCP e HTTP(S).
set -u

ajuda() {
    cat <<'EOF'
Uso: check-network.sh HOST PORTA URL [TIMEOUT_SEGUNDOS]

Exemplo:
  ./check-network.sh example.com 443 https://example.com/ 5

HOST aceita nomes DNS ou IPv4 (sem espaços). PORTA: 1–65535.
URL deve começar por http:// ou https:// e não conter credenciais.
O tempo limite, de 1 a 60 segundos, vale para cada teste.
Os testes não seguem redirecionamentos. HTTP 2xx/3xx é considerado resposta;
4xx/5xx é falha. A validação do certificado HTTPS continua ativa.
O TCP testa apenas o primeiro endereço IPv4. IPv6 não é testado pelo TCP.
A rota consultada é a rota padrão IPv4, não necessariamente a usada pelo destino.

Códigos: 0 = verificações necessárias passaram; 1 = falha de rede ou HTTP;
2 = argumento, dependência ou consulta local inválida.
EOF
}
if [ "$#" -eq 1 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ]; }; then
    ajuda; exit 0
fi
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Erro: informe HOST, PORTA, URL e timeout opcional. Use --help." >&2
    exit 2
fi
host=$1
porta=$2
url=$3
tempo=${4:-5}
if [[ ! "$host" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]] || [ "${#host}" -gt 253 ]; then
    echo "Erro: host inválido; informe nome DNS ou IPv4." >&2; exit 2
fi
if [[ ! "$porta" =~ ^[0-9]{1,5}$ ]] || (( 10#$porta < 1 || 10#$porta > 65535 )); then
    echo "Erro: porta deve ser um inteiro entre 1 e 65535." >&2; exit 2
fi
porta=$((10#$porta))
if [[ ! "$tempo" =~ ^[0-9]{1,2}$ ]] || (( 10#$tempo < 1 || 10#$tempo > 60 )); then
    echo "Erro: timeout deve ser um inteiro entre 1 e 60." >&2; exit 2
fi
tempo=$((10#$tempo))
if [[ ! "$url" =~ ^https?://[^/?#[:space:]@]+([/?#][^[:space:]]*)?$ ]] || [[ "$url" == *"@"* ]] || [[ "$url" == *"?"* ]] || [[ "$url" == *"#"* ]]; then
    echo "Erro: URL deve ser HTTP(S), sem credenciais, query ou fragmento." >&2; exit 2
fi
for ferramenta in ip getent timeout curl; do
    if ! command -v "$ferramenta" >/dev/null 2>&1; then
        echo "Erro: dependência ausente: $ferramenta" >&2; exit 2
    fi
done

falha=0
erro=0
echo "=== Diagnóstico de rede ==="
echo "Host: $host | Porta: $porta | Timeout por teste: ${tempo}s"

if rota=$(ip -4 route show default 2>&1); then
    if [ -n "$rota" ]; then
        echo "ROTA IPv4: $rota"
    else
        echo "ROTA IPv4: nenhuma rota padrão encontrada (pode ser esperado para destinos locais)."
    fi
else
    echo "ERRO: não foi possível consultar a rota IPv4." >&2
    erro=1
fi

if timeout "${tempo}s" getent ahosts "$host" >/dev/null 2>&1; then
    echo "RESOLUÇÃO: OK ($host)"
else
    echo "RESOLUÇÃO: falhou ou excedeu o tempo ($host)"
    falha=1
fi

# Testa o primeiro endereço IPv4 resolvido; não avalia IPv6 nem todos os IPs.
ipv4=""
if enderecos=$(timeout "${tempo}s" getent ahostsv4 "$host" 2>/dev/null); then
    read -r ipv4 _ <<< "$enderecos"
fi
if [[ ! "$ipv4" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "TCP IPv4: sem endereço IPv4 disponível para testar"
    falha=1
elif timeout "${tempo}s" bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$ipv4" "$porta" 2>/dev/null; then
    echo "TCP IPv4: conexão estabelecida ($ipv4:$porta)"
else
    echo "TCP IPv4: falhou ou excedeu o tempo ($ipv4:$porta)"
    falha=1
fi

# Não seguir redirects e não imprimir corpo nem URL potencialmente sensível.
if codigo=$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --connect-timeout "$tempo" --max-time "$tempo" --proto '=http,https' \
    --noproxy '*' -- "$url" 2>/dev/null); then
    if [[ "$codigo" =~ ^[23][0-9][0-9]$ ]]; then
        echo "HTTP: resposta $codigo"
    else
        echo "HTTP: resposta $codigo (fora de 2xx/3xx)"
        falha=1
    fi
else
    echo "HTTP: falha de conexão, TLS ou tempo esgotado"
    falha=1
fi

echo "Nota: DNS/TCP usam HOST; HTTP usa o destino da URL, que pode ser diferente."
if [ "$erro" -eq 1 ]; then exit 2; fi
if [ "$falha" -eq 1 ]; then exit 1; fi
exit 0
