# Runbook — Diagnóstico de rede e DNS

## Objetivo e escopo

Investigar do enlace à aplicação e alterar Netplan somente quando necessário. DNS configurado, ping e porta aberta são evidências diferentes.

## Estado de validação

- Revisão documental: 26/10/2026.
- Ambiente-alvo: Ubuntu Server com systemd; confirmar versões e ferramentas locais.
- Execução em laboratório: pendente. Exemplos não foram executados na VPS por esta entrega.
- Adaptar nomes, interfaces, dispositivos e endereços antes de executar.
- Consultas e mudanças estão identificadas nas etapas; não executar todos os blocos indiscriminadamente.

## Pré-requisitos

- Sudo para inspeção completa; console para mudanças de rede.
- Conhecer interface, CIDR, gateway, DNS e destino esperado.
- dnsutils e curl para testes; netcat-openbsd e traceroute opcionais.
- Identificar se Netplan, cloud-init ou NetworkManager administra a rede.

## Impacto e condição para interromper

Alterações podem interromper SSH e aplicações. Não modificar IP/rota para corrigir problema de aplicação sem evidência. Não substituir DNS corporativo por público sem avaliar zonas internas.

## 1. Interface, endereço e rota — consulta

```bash
ip -br link
ip -br address
ip route
ip -6 route
ip route get 1.1.1.1
```

Verificar interface UP, endereço/máscara e saída selecionada. O endereço usado no exemplo serve apenas para consultar a decisão de roteamento.

## 2. Resolução — consulta e testes

```bash
resolvectl status
readlink -f /etc/resolv.conf
getent ahosts example.com
dig example.com A
dig example.com AAAA
```

getent usa o mecanismo de resolução do sistema; dig consulta DNS. Examinar search domains e DNS por interface/VPN.
127.0.0.53 pode ser o stub local do systemd-resolved; não é evidência de erro.
Para comparar com um servidor autorizado, adaptar:

```bash
dig @192.0.2.53 example.com A
```

192.0.2.53 é exemplo documental, não um DNS real a configurar.
NXDOMAIN, SERVFAIL e timeout exigem diagnósticos diferentes. Não editar resolv.conf gerenciado diretamente.

## 3. Transporte e aplicação — testes

```bash
ping -c 4 example.com
curl -I --connect-timeout 5 --max-time 15 https://example.com
```

Com netcat instalado:

```bash
nc -vz -w 5 example.com 443
```

ICMP pode ser bloqueado mesmo com HTTPS funcional. Conexão TCP não valida autenticação ou conteúdo.
Para testar origem conhecida sem mudar DNS, usar o IP real autorizado:

```bash
curl --resolve example.com:443:192.0.2.10 --connect-timeout 5 --max-time 15 https://example.com/
```

Esse exemplo só funciona quando o endereço for substituído. Não usar -k para esconder erro TLS.

## 4. Capturar contexto de falha — consulta

```bash
sudo ss -tulpn
sudo journalctl -u systemd-networkd -u systemd-resolved --since '30 minutes ago' --no-pager
```

Adaptar unidades ao gerenciador em uso. Captura de pacotes, se necessária, deve ter filtro, duração e destino definidos para evitar exposição de dados.

## 5. Netplan — alteração condicional

```bash
sudo netplan get
sudo ls -l /etc/netplan
```

A saída pode conter dados internos: não publicar sem revisar.
Preservar arquivos e verificar se cloud-init os recria. Editar somente o YAML correto; não criar configurações concorrentes para a mesma interface.
Após alteração revisada e com console disponível:

```bash
sudo netplan generate
sudo netplan try --timeout 120
```

generate valida e gera configuração; try aplica temporariamente e pede confirmação. Validar por uma segunda conexão antes de confirmar. Existem limitações de rollback: verificar a rede e os arquivos mesmo após timeout. Se try não suportar a topologia, planejar aplicação pelo console.

## 6. Aceite
Repetir IP/rotas, DNS e teste da aplicação, incluindo IPv6 quando usado.
Persistência após reboot só deve ser testada em janela e com console disponível.

## Recuperação

Pelo console, restaurar os YAML preservados, validar com netplan generate e aplicar a configuração anterior. Conferir configuração em disco e estado efetivo; timeout do try não deve ser a única estratégia de recuperação.

## Exercício de validação

Em VM descartável, investigar um nome inexistente e uma porta fechada; explicar as diferenças. Testar mudança de DNS com recuperação e verificar persistência após reboot.

## Registro da execução

- Data, responsável e versão do sistema:
- Objetivo e estado anterior:
- Comandos e arquivos alterados, sem segredos:
- Resultado esperado e observado:
- Evidências sanitizadas:
- Recuperação utilizada:
- Pendências e próximo responsável:

## Referências

- https://netplan.readthedocs.io/en/stable/netplan-try/
- https://ubuntu.com/server/docs/explanation/networking/configuring-networks/
