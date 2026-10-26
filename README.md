# Infra Runbooks

Procedimentos práticos de infraestrutura Linux e Windows Server,
com comandos, diagnóstico, validação e recuperação.

Autor: Gabriel Palhano Gomes

## Plano de implementação

Consulte o [checklist mestre de Linux, Windows e observabilidade](ROADMAP.md).
Ele separa documentação, scripts planejados, verificações e critérios de aceite.

## Procedimentos Linux

| Procedimento | Objetivo |
|---|---|
| [01 — Inspeção inicial](linux/01-inspecao-inicial.md) | Levantar sistema, recursos, rede e serviços |
| [02 — Atualização do sistema](linux/02-atualizacao-do-sistema.md) | Planejar atualizações e validar a manutenção |
| [03 — Usuários e SSH](linux/03-usuarios-e-acesso-ssh.md) | Configurar e validar acesso administrativo |
| [04 — Disco e logs](linux/04-disco-e-gerenciamento-de-logs.md) | Investigar consumo e gerenciar retenção |
| [05 — Serviços systemd](linux/05-servicos-systemd.md) | Diagnosticar e operar serviços |

| [06 — Preparação inicial](linux/06-preparacao-inicial.md) | Identidade, horário, pacotes e checklist |
| [07 — Rede e DNS](linux/07-rede-e-dns.md) | Interface, rotas, resolução e Netplan |
| [08 — Firewall UFW](linux/08-firewall-ufw.md) | Regras, VPN, IPv6 e Docker |
| [09 — Backup e restauração](linux/09-backup-e-restauracao.md) | Restic, integridade, retenção e recuperação |
| [10 — Desempenho e processos](linux/10-desempenho-e-processos.md) | CPU, memória, I/O e OOM |
| [11 — Permissões e ACLs](linux/11-permissoes-e-acls.md) | Acesso mínimo, grupos e herança |
| [12 — Agendamentos](linux/12-agendamentos-cron-e-timers.md) | Cron, timers, logs e concorrência |
| [13 — Nginx e HTTPS](linux/13-nginx-e-https.md) | Proxy, certificados e renovação |
| [14 — Discos e montagens](linux/14-discos-montagens-e-expansao.md) | UUID, fstab e expansão ext4 em laboratório |
| [15 — Segurança e auditoria](linux/15-seguranca-e-auditoria.md) | Acessos, exposição, patches e evidências |

## Como utilizar

1. Leia o procedimento completo antes de executar.
2. Confira pré-requisitos, impacto e recuperação.
3. Adapte os exemplos ao ambiente.
4. Execute as etapas necessárias e interprete os resultados.
5. Valide o funcionamento das aplicações.
6. Registre alterações, evidências e pendências.
7. Remova IPs, nomes internos e segredos antes de publicar evidências.

## Organização

- linux/: procedimentos para Linux.
- windows/: reservado para Windows Server e Active Directory.
- scripts/: reservado para futuras automações.

## Validação

Os 15 procedimentos estão publicados como documentação em evolução.
Os novos runbooks 06–15 possuem revisão documental e execução em laboratório pendente.
A publicação não comprova execução dos comandos nem compatibilidade com todo ambiente.

A base usa Ubuntu Server e systemd. Comandos APT, UFW e caminhos de pacotes
não devem ser aplicados sem adaptação a outras distribuições.

Cada novo documento inclui pré-requisitos, impacto, etapas de consulta e alteração,
validação, recuperação, exercício de laboratório e fontes oficiais ou manuais upstream.

Use o [modelo de registro de validação](templates/registro-validacao.md) para documentar testes.
Não confundir verificação de sintaxe dos exemplos com teste funcional.

## Próximas entregas

- Automação da coleta de informações.
- Execução dos laboratórios Linux e registro dos resultados.
- Inspeção de Windows Server e Active Directory.
