# Runbook — Inspeção inicial de servidor Linux

## Objetivo
Identificar configuração, recursos, serviços e possíveis falhas antes de realizar mudanças.

## Pré-requisitos
- Acesso ao servidor.
- Permissão sudo para consultas administrativas.
- Conhecimento dos serviços que devem estar ativos.

## 1. Identificar o sistema

```bash
cat /etc/os-release
hostnamectl
uname -r
```

Verificar distribuição, versão, hostname, virtualização e kernel.

## 2. Conferir recursos

```bash
lscpu
free -h
lsblk -f
df -hT
```

Verificar CPUs disponíveis, memória disponível, swap e ocupação dos discos.
Swap utilizada isoladamente não confirma falta de memória.

## 3. Conferir rede e horário

```bash
ip -br address
ip route
resolvectl status
timedatectl
```

Verificar interfaces, rota padrão, DNS configurado e sincronização do relógio.
Se resolvectl não estiver disponível, consultar /etc/resolv.conf.
DNS configurado não comprova que a resolução funciona.

## 4. Conferir saúde do sistema

```bash
systemctl --failed
systemctl is-system-running
sudo journalctl -b -p err --since "1 hour ago" --no-pager -n 50
```

Investigar unidades em falha e correlacionar erros com sintomas.
Ausência de erros no journal não comprova saúde das aplicações.

## 5. Conferir containers, quando houver Docker

```bash
sudo docker compose ls -a
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
sudo docker stats --no-stream
```

Comparar o estado observado com os serviços esperados.
Container em execução não comprova que a aplicação está saudável.
Investigar encerramentos inesperados antes de reiniciar.

## 6. Conferir portas e firewall

```bash
sudo ss -tulpn
sudo ufw status verbose
```

Consultar o UFW quando estiver instalado.
Comparar portas em escuta com os acessos necessários.
Avaliar também regras do provedor, IPv6 e publicação de portas pelo Docker.
Esta consulta não substitui um teste externo de acesso.

## 7. Validar Nginx, quando instalado

```bash
sudo nginx -t
```

Resultado esperado: teste de configuração bem-sucedido.
Validar separadamente as URLs e os serviços publicados.

## Critérios de conclusão
- Inventário registrado.
- Serviços comparados com o estado esperado.
- Falhas e dúvidas documentadas com evidências.
- Testes funcionais pendentes identificados.

## Reversão
As consultas deste procedimento não alteram a configuração dos serviços.

## Registro da execução
- Data:
- Responsável:
- Ambiente:
- Serviços esperados:
- Resultados:
- Pendências:
