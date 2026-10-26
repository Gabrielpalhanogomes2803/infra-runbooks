# Runbook — Preparação inicial de servidor Ubuntu

## Objetivo e escopo

Preparar uma VM recém-instalada e estabelecer uma base administrativa. Não aplicar integralmente a um servidor existente sem inventariar suas aplicações. Instalação de banco, Docker e agentes tem procedimento próprio.

## Estado de validação

- Revisão documental: 26/10/2026.
- Ambiente-alvo: Ubuntu Server com systemd; confirmar versões e ferramentas locais.
- Execução em laboratório: pendente. Exemplos não foram executados na VPS por esta entrega.
- Adaptar nomes, interfaces, dispositivos e endereços antes de executar.
- Consultas e mudanças estão identificadas nas etapas; não executar todos os blocos indiscriminadamente.

## Pré-requisitos

- VM de laboratório, usuário com sudo e console do hipervisor/provedor.
- Função do servidor, hostname e política de horário definidos.
- Rede funcional, fontes APT aprovadas e backup/ponto de recuperação.
- Ler [inspeção](01-inspecao-inicial.md), [atualizações](02-atualizacao-do-sistema.md), [SSH](03-usuarios-e-acesso-ssh.md) e [firewall](08-firewall-ufw.md).

## Impacto e condição para interromper

Instalações podem iniciar serviços. Hostname pode afetar integrações; firewall e SSH podem bloquear acesso. Interromper se houver aplicações desconhecidas ou erros de repositório.

## 1. Inventário anterior — consulta

```bash
cat /etc/os-release
hostnamectl
ip -br address
ip route
free -h
df -hT
timedatectl
systemctl --failed
```

Esperado: distribuição identificada, espaço livre, rota e horário conhecidos. Registrar falhas anteriores.

## 2. Definir identidade e horário — alteração
Somente após confirmar que o nome não participa de integrações existentes:

```bash
sudo hostnamectl set-hostname lab-linux-01
```

Revisar /etc/hosts para coerência com o nome local; preservar entradas do provedor.
Usar UTC ou o fuso exigido pela operação; exemplo:

```bash
sudo timedatectl set-timezone Etc/UTC
timedatectl
```

Verificar sincronização. Identificar o cliente NTP existente; não instalar um segundo cliente concorrente.

## 3. Selecionar pacotes por finalidade
| Grupo | Pacotes sugeridos | Uso |
|---|---|---|
| Base administrativa | ca-certificates, curl, less, nano, sudo | Certificados, consultas e administração |
| Rede | dnsutils, iputils-ping, traceroute, netcat-openbsd | DNS, ICMP, rotas e TCP |
| Diagnóstico | lsof, sysstat, procps | Arquivos abertos, CPU e I/O |
| Arquivos | rsync, acl | Cópia e permissões estendidas |
| Sessão remota | tmux | Manter sessão de manutenção |
| Conforme a função | openssh-server, ufw, nginx, restic | Instalar apenas se necessário |

Consultar disponibilidade e versões:

```bash
apt-cache policy ca-certificates curl less nano sudo tmux
sudo apt update
sudo apt --simulate install ca-certificates curl less nano sudo tmux
```

Se a simulação estiver adequada:

```bash
sudo apt install ca-certificates curl less nano sudo tmux
```

Instalar grupos opcionais separadamente, com a mesma revisão. Não instalar todas as ferramentas por padrão. Não usar scripts remotos via curl | bash.

## 4. Estabelecer acesso administrativo
Seguir o runbook SSH para conta individual, chave pública, sudo e segunda conexão.
Registrar o caminho de recuperação pelo console. Aplicar o firewall somente após confirmar esse acesso.

## 5. Atualização e reinicialização
Seguir o runbook de atualização. Confirmar serviços esperados antes de qualquer reboot.

## 6. Aceite — consulta e testes

```bash
hostnamectl
timedatectl
systemctl --failed
sudo ss -tulpn
```

Validar nova sessão SSH, sudo, DNS e conectividade HTTPS. Conferir que só os serviços previstos foram instalados. Registrar inventário e configuração-base sem credenciais.

## Recuperação

Restaurar hostname/fuso anteriores e os arquivos modificados. Remover pacotes somente após revisar dependências e dados criados. Reverter a VM pelo ponto de recuperação se necessário; não presumir que desinstalar desfaz toda configuração.

## Exercício de validação

Preparar uma VM limpa, reconectar por chave, reiniciar e repetir a inspeção. Anexar resultados sanitizados e versões dos pacotes; só então marcar o procedimento como validado.

## Registro da execução

- Data, responsável e versão do sistema:
- Objetivo e estado anterior:
- Comandos e arquivos alterados, sem segredos:
- Resultado esperado e observado:
- Evidências sanitizadas:
- Recuperação utilizada:
- Pendências e próximo responsável:

## Referências

- https://ubuntu.com/server/docs/
- https://ubuntu.com/server/docs/openssh-server/
