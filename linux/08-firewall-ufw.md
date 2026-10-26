# Runbook — Firewall UFW e exposição de serviços

## Objetivo e escopo

Inventariar e aplicar regras para o host Ubuntu. Redes Docker, VPN e firewall do provedor precisam ser avaliados em conjunto.

## Estado de validação

- Revisão documental: 26/10/2026.
- Ambiente-alvo: Ubuntu Server com systemd; confirmar versões e ferramentas locais.
- Execução em laboratório: pendente. Exemplos não foram executados na VPS por esta entrega.
- Adaptar nomes, interfaces, dispositivos e endereços antes de executar.
- Consultas e mudanças estão identificadas nas etapas; não executar todos os blocos indiscriminadamente.

## Pré-requisitos

- Sudo, console funcional e duas sessões administrativas.
- Porta SSH real, interface VPN e origens autorizadas identificadas.
- UFW instalado e ferramenta de firewall proprietária identificada.
- Não misturar gerenciadores de firewall sem compreender as regras efetivas.

## Impacto e condição para interromper

Pode bloquear acesso remoto e tráfego das aplicações. Interromper se não houver console ou se o caminho administrativo não estiver confirmado. Política routed pode afetar VPN, containers e encaminhamento.

## 1. Inventário — consulta

```bash
sudo ufw status verbose
sudo ufw status numbered
sudo ss -tulpn
ip -br address
sudo cat /etc/default/ufw
```

Conferir IPV6 e todas as portas necessárias. Se disponíveis, consultar sem alterar:

```bash
sudo nft list ruleset
sudo iptables-save
```

Guardar saídas em local restrito. Identificar backend utilizado e firewall do provedor.

## 2. Preservar configuração
Criar cópia restrita e identificada de /etc/ufw e /etc/default/ufw.
Registrar regras anteriores e caminho do console. Não executar ufw reset como preparação.

## 3. Garantir acesso administrativo — alteração condicional
Escolher apenas o exemplo compatível com o ambiente.
Para SSH pela interface Tailscale existente:

```bash
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH via Tailscale'
```

Confirmar a política de acesso do Tailscale e conectividade da VPN separadamente.
Para SSH público restrito a uma origem, adaptar IP e porta:

```bash
sudo ufw allow from 198.51.100.10/32 to any port 22 proto tcp comment 'SSH administrativo'
```

198.51.100.10 é documental. Não executar com esse valor esperando liberar seu IP.

## 4. Regras da aplicação — alteração condicional
Para um servidor web que realmente deve receber tráfego público:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

Não abrir banco, Grafana ou Prometheus publicamente por conveniência.
Revisar IPv4 e IPv6, além das regras do provedor.

## 5. Políticas e ativação
Somente após planejar todos os fluxos necessários:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw status verbose
```

Não redefinir encaminhamento automaticamente: avaliar os fluxos roteados existentes.
Em servidor com UFW ativo, cada nova regra já pode produzir efeito imediatamente.

## 6. Docker exige validação separada

```bash
sudo docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Portas publicadas pelo Docker podem desviar do caminho filtrado pelo UFW.
Para serviço somente local, avaliar publicação como 127.0.0.1:3000:3000.
Isso pode exigir recriação do container e não impede publicação via proxy.
Não desativar as regras de firewall geradas pelo Docker.
Filtros adicionais devem seguir o backend e a documentação da versão instalada.

## 7. Aceite externo
Sem fechar a sessão original, abrir nova conexão pelo caminho permitido.
De outra máquina autorizada, testar portas permitidas e uma porta que deve estar bloqueada.
Testar aplicação, VPN, IPv6 e containers. Uma consulta local não comprova bloqueio externo.

## 8. Remover regra específica — alteração

```bash
sudo ufw status numbered
```

Após identificar a regra, usar ufw delete NUMERO_DA_REGRA com o número real.
Listar novamente após cada exclusão: a numeração muda.

## Recuperação

Usar console/sessão existente para corrigir a regra que bloqueou o fluxo. Restaurar arquivos preservados e recarregar somente após revisão. Desabilitar UFW é medida emergencial que expõe serviços: preferir correção específica e restabelecer a política imediatamente.

## Exercício de validação

Em VM descartável, permitir SSH pela origem prevista, bloquear uma porta de teste e confirmar externamente. Incluir teste com porta Docker publicada para demonstrar a diferença.

## Registro da execução

- Data, responsável e versão do sistema:
- Objetivo e estado anterior:
- Comandos e arquivos alterados, sem segredos:
- Resultado esperado e observado:
- Evidências sanitizadas:
- Recuperação utilizada:
- Pendências e próximo responsável:

## Referências

- https://ubuntu.com/server/docs/firewalls/
- https://docs.docker.com/engine/network/packet-filtering-firewalls/
