<div align="center">

# Infra Runbooks

**Procedimentos e automações para operar infraestrutura com clareza e segurança.**

Linux · Windows Server · Observabilidade · DevOps

[Explorar runbooks](#runbooks-linux) · [Usar os scripts](#scripts-linux) · [Ver planejamento](ROADMAP.md)

</div>

---

## Sobre o projeto

O **Infra Runbooks** reúne procedimentos operacionais, scripts e registros de validação para apoiar o diagnóstico e a manutenção de servidores.

Cada runbook procura responder: **o que verificar, como executar, como validar e como recuperar**. O projeto está em evolução, com foco atual em Linux e expansão planejada para Windows Server e observabilidade.

| O que existe hoje | Estado |
|---|---|
| 15 runbooks Linux | Publicados; validação prática varia por procedimento |
| Inventário Linux | Script implementado e testado na VPS |
| Verificação de armazenamento | Script implementado e testado na VPS |
| Windows Server e observabilidade | Planejados no [checklist mestre](ROADMAP.md) |

## Comece por aqui

1. Escolha o procedimento na lista abaixo e leia os pré-requisitos, impactos e recuperação.
2. Adapte os exemplos ao ambiente e execute as verificações necessárias.
3. Compare o resultado com o comportamento esperado e teste a aplicação.
4. Registre evidências no [modelo de validação](templates/registro-validacao.md).

> **Antes de compartilhar resultados:** remova IPs, nomes internos, identificadores, segredos e outras informações sensíveis. Um comando executado com sucesso não comprova, sozinho, que a aplicação está saudável.

## Runbooks Linux

| Nº | Procedimento | Objetivo |
|:--:|---|---|
| 01 | [Inspeção inicial](linux/01-inspecao-inicial.md) | Inventariar sistema, recursos, rede e serviços |
| 02 | [Atualização do sistema](linux/02-atualizacao-do-sistema.md) | Planejar atualizações e validar a manutenção |
| 03 | [Usuários e SSH](linux/03-usuarios-e-acesso-ssh.md) | Configurar e validar acesso administrativo |
| 04 | [Disco e logs](linux/04-disco-e-gerenciamento-de-logs.md) | Investigar consumo e retenção |
| 05 | [Serviços systemd](linux/05-servicos-systemd.md) | Diagnosticar e operar serviços |
| 06 | [Preparação inicial](linux/06-preparacao-inicial.md) | Configurar identidade, horário e pacotes |
| 07 | [Rede e DNS](linux/07-rede-e-dns.md) | Investigar interfaces, rotas e resolução |
| 08 | [Firewall UFW](linux/08-firewall-ufw.md) | Avaliar regras, VPN, IPv6 e Docker |
| 09 | [Backup e restauração](linux/09-backup-e-restauracao.md) | Planejar cópias e testar recuperação |
| 10 | [Desempenho e processos](linux/10-desempenho-e-processos.md) | Investigar CPU, memória, I/O e OOM |
| 11 | [Permissões e ACLs](linux/11-permissoes-e-acls.md) | Diagnosticar acesso a arquivos |
| 12 | [Agendamentos](linux/12-agendamentos-cron-e-timers.md) | Operar cron e systemd timers |
| 13 | [Nginx e HTTPS](linux/13-nginx-e-https.md) | Verificar proxy, certificados e renovação |
| 14 | [Discos e montagens](linux/14-discos-montagens-e-expansao.md) | Analisar UUID, fstab e expansão em laboratório |
| 15 | [Segurança e auditoria](linux/15-seguranca-e-auditoria.md) | Revisar acesso, exposição e atualizações |

## Scripts Linux

Os dois scripts abaixo **fazem consultas**. Revise os comandos e as permissões antes de utilizá-los em outro ambiente.

### Inventário do servidor

[collect-system-info.sh](scripts/linux/collect-system-info.sh) reúne dados do sistema, recursos, rede e unidades systemd. Ele informa quando uma consulta falha e pode criar um relatório privado.

```bash
./scripts/linux/collect-system-info.sh --help
./scripts/linux/collect-system-info.sh
./scripts/linux/collect-system-info.sh --report
```

Para usar `--report`, crie antes o diretório de relatórios:

```bash
mkdir -p ~/infra-reports
chmod 700 ~/infra-reports
```

O arquivo é criado nesse diretório com acesso restrito e pode conter dados sensíveis.

| Código | Resultado |
|:--:|---|
| 0 | Coleta completa ou ajuda exibida |
| 1 | Erro na criação ou gravação do relatório |
| 2 | Argumento inválido |
| 3 | Coleta parcial |

**Testes registrados:** Ubuntu 26.04.1 LTS; coleta normal, relatório privado, argumento inválido, ferramenta ausente, diretório inexistente e falha simulada no gravador.

### Espaço e inodes

[check-storage.sh](scripts/linux/check-storage.sh) consulta o sistema de arquivos que contém o caminho informado, sem excluir arquivos ou alterar o armazenamento.

```bash
./scripts/linux/check-storage.sh --help
./scripts/linux/check-storage.sh /
./scripts/linux/check-storage.sh /var/log 90
```

O caminho padrão é `/` e o limite padrão é **80%**, aplicado tanto ao espaço quanto aos inodes. Dependências: Bash, `df` e `awk`.

| Código | Resultado |
|:--:|---|
| 0 | Espaço e inodes abaixo do limite |
| 1 | Pelo menos um limite atingido |
| 2 | Argumento inválido ou erro de consulta |

Sistemas de arquivos que não informam uso de inodes podem produzir erro de consulta.

**Testes registrados:** Ubuntu 26.04.1 LTS; execução normal, alerta com limite de teste, limite inválido e caminho inexistente.

## Organização

| Caminho | Conteúdo |
|---|---|
| [linux/](linux/) | Runbooks Linux |
| [scripts/linux/](scripts/linux/) | Scripts Linux disponíveis |
| [templates/](templates/) | Modelo para registrar validações |
| [ROADMAP.md](ROADMAP.md) | Checklist de Linux, Windows e observabilidade |

Windows Server e novas automações estão no planejamento; pastas vazias não são versionadas pelo Git.

## Validação e próximos passos

A base foi escrita principalmente para **Ubuntu Server com systemd**. Comandos APT, UFW e caminhos de pacotes exigem adaptação para outras distribuições.

Os runbooks **06–15** receberam revisão documental; a execução em laboratório ainda está pendente. Para os scripts, os testes realizados estão indicados acima. Verificação de sintaxe e testes parciais não validam todas as condições de operação.

Próximos passos:

- Evoluir as verificações de serviços e rede.
- Testar manutenção e restauração em laboratório.
- Criar inventário PowerShell para Windows Server.
- Conectar alertas de observabilidade a procedimentos de resposta.
- Adicionar verificações de qualidade no CI.

Acompanhe cada entrega e seus critérios no [checklist mestre](ROADMAP.md).

---

<div align="center">

**Gabriel Palhano Gomes** · Infraestrutura · Cloud · DevOps · SRE

[GitHub](https://github.com/Gabrielpalhanogomes2803) · [Portfólio](https://gabrielgomes.cloud)

</div>
