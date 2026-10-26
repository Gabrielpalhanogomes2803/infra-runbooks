# Infra Runbooks

Procedimentos práticos de infraestrutura Linux e Windows Server,
com comandos, diagnóstico, validação e recuperação.

Autor: Gabriel Palhano Gomes

## Procedimentos Linux

| Procedimento | Objetivo |
|---|---|
| [01 — Inspeção inicial](linux/01-inspecao-inicial.md) | Levantar sistema, recursos, rede e serviços |
| [02 — Atualização do sistema](linux/02-atualizacao-do-sistema.md) | Planejar atualizações e validar a manutenção |
| [03 — Usuários e SSH](linux/03-usuarios-e-acesso-ssh.md) | Configurar e validar acesso administrativo |
| [04 — Disco e logs](linux/04-disco-e-gerenciamento-de-logs.md) | Investigar consumo e gerenciar retenção |
| [05 — Serviços systemd](linux/05-servicos-systemd.md) | Diagnosticar e operar serviços |

## Como utilizar

1. Leia o procedimento completo antes de executar.
2. Confira pré-requisitos, impacto e recuperação.
3. Adapte os exemplos ao ambiente.
4. Execute as etapas necessárias e interprete os resultados.
5. Valide o funcionamento das aplicações.
6. Registre alterações, evidências e pendências.

## Organização

- linux/: procedimentos para Linux.
- windows/: reservado para Windows Server e Active Directory.
- scripts/: reservado para futuras automações.

## Validação

Documentação em evolução.
A presença de um procedimento não significa que todas as suas
etapas foram executadas ou testadas em todos os ambientes.

## Próximas entregas

- Automação da coleta de informações.
- Preparação inicial de servidor Linux.
- Inspeção de Windows Server e Active Directory.
