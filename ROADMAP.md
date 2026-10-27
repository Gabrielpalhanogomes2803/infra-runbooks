# Checklist mestre — Infraestrutura e automações

Plano de implementação e validação de Gabriel Palhano Gomes.
Ordem: **Linux → Windows → observabilidade → integração e portfólio**.
Atualizado em 27/10/2026.

## Como acompanhar

- [x] significa somente que a entrega descrita nessa linha foi concluída.
- Documento publicado não significa script implementado nem teste funcional aprovado.
- L01, L04, L05 e L07 já possuem primeira versão publicada; os demais scripts são propostas.
- Atualizar cada item somente com commit e evidência correspondente.
- Estados: planejado → implementado → revisado → testado em laboratório → documentado.
- Automação significa uma ferramenta executável; agendamento só entra após validação manual.
- Procedimentos de alteração exigem pré-checagens, acesso de recuperação e validação posterior.

## 0. Base já entregue

- [x] Publicar 15 runbooks Linux com índice.
- [x] Criar modelo de registro em templates/registro-validacao.md.
- [x] Revisar sintaxe de 85 blocos Bash da entrega 06–15 e ajustes associados.
- [x] Conferir links internos dessa entrega e conteúdo publicado no GitHub.
- [ ] Registrar execução prática de cada runbook; a revisão documental não substitui esse aceite.
- [ ] Definir VM limpa e mecanismo de recuperação antes dos testes de alteração.
- [ ] Registrar distribuição, versão, ferramentas e topologia de cada laboratório.

## 1. Padrão obrigatório para scripts

- [ ] Ajuda --help, objetivo, dependências e exemplos.
- [ ] Separar coleta sem alteração de operações que modificam o sistema.
- [ ] Validar parâmetros, caminhos, privilégios e ferramentas ausentes.
- [ ] Não instalar dependências silenciosamente durante uma consulta.
- [ ] Usar códigos de saída claros; distinguir erro, alerta e ferramenta ausente.
- [ ] Aplicar timeouts a consultas de rede e ferramentas externas.
- [ ] Proteger relatórios e logs; não imprimir senhas, tokens ou chaves.
- [ ] Salvar relatórios fora dos arquivos versionados; definir .gitignore.
- [ ] Suportar repetição segura e concorrência quando aplicável.
- [ ] Documentar limites: dry-run não garante ausência de impacto.
- [ ] Fornecer pré-checagem e recuperação nas operações de alteração.
- [ ] Testar caminho de sucesso e falhas reais, não apenas sintaxe.
- [ ] Não usar nome do processo/serviço fixo quando houver parâmetro apropriado.
- [ ] Evitar coleta excessiva de dados pessoais e conteúdo de logs.

## 2. Linux — procedimentos, scripts e aceite

L01, L04 e L05 estão implementados com testes parciais na VPS. L07 tem testes isolados; demais scripts estão planejados.

| ID | Documento existente | Script proposto | Verificação de aceite |
|---|---|---|---|
| L01 | 01 — Inspeção inicial | scripts/linux/collect-system-info.sh | Relatório de OS, recursos, rede e serviços; continua quando ferramenta opcional falta |
| L02 | 02 — Atualização | scripts/linux/check-updates.sh | Índice identificado, pendências/holds/reboot reportados; sem instalar ou reiniciar |
| L03 | 03 — Usuários/SSH | scripts/linux/audit-ssh-access.sh | Configuração efetiva e permissões verificadas sem mostrar chaves |
| L04 | 04 — Disco/logs | scripts/linux/check-storage.sh | Espaço, inodes e journal; nenhum dado excluído |
| L05 | 05 — systemd | scripts/linux/check-services.sh | Unidades esperadas por parâmetro, estado e falhas com código de saída |
| L06 | 06 — Preparação inicial | scripts/linux/bootstrap-precheck.sh | Pré-requisitos e pacotes por função; instalação separada da consulta |
| L07 | 07 — Rede/DNS | scripts/linux/check-network.sh | DNS, rota, TCP e HTTP diferenciados, com timeout |
| L08 | 08 — UFW | scripts/linux/audit-firewall.sh | Portas/regras/Docker reportados; acesso permitido e bloqueado testado externamente |
| L09 | 09 — Backup | scripts/linux/backup-files.sh e restore-test.sh | Destino confirmado, erro monitorado e restauração isolada comprovada |
| L10 | 10 — Desempenho | scripts/linux/collect-performance.sh | Amostras limitadas de CPU, memória, I/O e PSI; sem gerar carga |
| L11 | 11 — Permissões | scripts/linux/check-path-access.sh | Conta/caminho por parâmetro, pais e ACLs avaliados; sem chmod/chown |
| L12 | 12 — Agendamentos | scripts/linux/check-scheduled-jobs.sh | Timer/tarefa atrasada e falha detectados; não duplica execução |
| L13 | 13 — Nginx/HTTPS | scripts/linux/check-web-tls.sh | Configuração, HTTP e certificado do domínio correto; sem ignorar erro TLS |
| L14 | 14 — Discos | scripts/linux/check-mounts.sh | UUID, montagem exata e capacidade coerentes; não formata nem amplia |
| L15 | 15 — Segurança | scripts/linux/security-baseline.sh | Achados classificados e limitados ao escopo; não declara servidor “seguro” |

### Implementação e validação

- [ ] L01 — primeira versão publicada e testes parciais registrados no README: coleta, ferramenta ausente, argumento inválido e falha simulada no gravador. Pendente: testes adicionais, revisão de segurança da gravação e registro formal.
- [ ] L02 — implementar consulta; validar manutenção manual e reboot em VM separadamente.
- [ ] L03 — implementar consulta; testar chave, sudo e recuperação em nova sessão.
- [ ] L04 — script publicado e testado na VPS; testes isolados simulam montagem com espaços e ausência de percentual de inodes. Pendente: validação dessas condições na VPS e registro formal. A consulta de journal ainda não foi implementada.
- [ ] L05 — script publicado e testado na VPS; testes isolados simulam unidade em falha e prioridade de condições combinadas. Pendente: teste de unidade real em falha e registro formal.
- [ ] L06 — implementar pré-checagem; executar preparação manual em VM limpa.
- [ ] L07 — script implementado; testes isolados para DNS inexistente, TCP fechado, HTTP 500 e parâmetros inválidos. Teste na VPS de 27/10 mostrou IPv6 expirando no curl e resposta HTTP 200; teste TCP foi ajustado para IPv4 e precisa ser repetido. Pendente: timeout específico e registro formal.
- [ ] L08 — implementar auditoria; testar caminhos externos IPv4/IPv6 e Docker.
- [ ] L09 — implementar backup/restauração; testar destino ausente, erro de acesso e arquivo recuperado.
- [ ] L10 — implementar coleta; comparar cenário normal e carga controlada no laboratório.
- [ ] L11 — implementar; testar conta permitida, negada e bloqueio em diretório pai.
- [ ] L12 — implementar; validar tarefa atrasada, lock ocupado e execução perdida.
- [ ] L13 — implementar; testar backend indisponível, DNS incorreto e certificado de teste inválido.
- [ ] L14 — implementar consulta; validar montagem e expansão manual somente em disco secundário.
- [ ] L15 — implementar consulta; testar achados fictícios e eliminar falsos positivos conhecidos.

### Operações de alteração — fase posterior

- [ ] Avaliar bootstrap idempotente somente após procedimento manual validado.
- [ ] Avaliar atualização assistida, sem upgrade/reboot automáticos por padrão.
- [ ] Avaliar hardening SSH e regras de firewall com console e nova sessão.
- [ ] Implantar timers de backup e verificação com alerta de falha.
- [ ] Manter limpeza de dados, reparticionamento e restauração de produção fora de ações genéricas.

## 3. Windows Server — primeiro leitura e diagnóstico

Definir versão, edição, PowerShell, domínio e funções instaladas.
Preferir comandos CIM e módulos suportados; não depender de ferramentas legadas sem necessidade.
AD, DNS, DFSR e Hyper-V devem ser testados em laboratório separado do domínio real.

| ID | Procedimento a escrever | Script PowerShell proposto | Aceite |
|---|---|---|---|
| W01 | Inventário Windows Server | Get-ServerInventory.ps1 | OS, funções, recursos, volumes e uptime em relatório |
| W02 | Atualizações e reboot pendente | Test-UpdateReadiness.ps1 | Fontes/política e sinais de pendência documentados, sem reboot |
| W03 | Serviços e inicialização | Test-RequiredServices.ps1 | Lista esperada e falhas identificadas |
| W04 | Rede, DNS e horário | Test-NetworkHealth.ps1 | DNS, rota, TCP e sincronização diferenciados |
| W05 | Disco e armazenamento | Get-StorageHealth.ps1 | Capacidade/erros e volumes esperados, sem limpeza |
| W06 | Eventos e reinicializações | Get-SystemEventSummary.ps1 | Janela e IDs parametrizados; reinício planejado versus inesperado |
| W07 | AD e replicação | Test-ADHealth.ps1 | Diagnóstico com módulos/ferramentas disponíveis e escopo definido |
| W08 | DNS do domínio | Test-ADDnsHealth.ps1 | Resolução interna e registros de serviço em laboratório |
| W09 | DFSR e backlog | Get-DFSRHealth.ps1 | Grupo/pasta/parceiros corretos, fila por direção e evolução |
| W10 | Contas e grupos | Get-ADChangeSummary.ps1 | Eventos e alterações com auditoria prévia e acesso restrito |
| W11 | NTFS e compartilhamentos | Get-ShareAccessReport.ps1 | Permissão efetiva considera compartilhamento e NTFS |
| W12 | Hyper-V e VMs | Get-HyperVHealth.ps1 | Host, estado de VMs, armazenamento e eventos |
| W13 | Backup/VSS e restauração | Test-BackupHealth.ps1 | Último sucesso, falha/atraso e restauração comprovada |
| W14 | Firewall e acesso remoto | Get-RemoteAccessAudit.ps1 | Regras, perfis, RDP/WinRM e origem permitida |

### Checklist Windows

- [ ] Escrever e revisar W01–W06; implementar scripts de consulta.
- [ ] Escrever e revisar W07–W11 em domínio de laboratório.
- [ ] Escrever e revisar W12–W14 conforme funções disponíveis.
- [ ] Tratar execução sem privilégio e módulo ausente.
- [ ] Exportar JSON/CSV com codificação e esquema documentados.
- [ ] Usar parâmetros, ajuda e -WhatIf quando a operação suportar mudança.
- [ ] Não armazenar senha em texto claro; definir autenticação e acesso remoto.
- [ ] Evitar mudanças automáticas em GPO, AD, DFSR e permissões.
- [ ] Testar PSScriptAnalyzer e testes Pester relevantes aos comportamentos.
- [ ] Registrar recuperação e evidências por procedimento.

## 4. Observabilidade — métricas, logs, alertas e diagnóstico

Aproveitar ai-sre-monitor e os laboratórios existentes.
infra-runbooks documenta a operação; configurações executáveis devem ter fonte de verdade definida.
Não manter cópias divergentes de dashboards ou regras entre repositórios.

| ID | Entrega | Verificação |
|---|---|---|
| O01 | Matriz serviço → sinal → alerta → responsável → runbook | Nenhum alerta crítico sem ação e dono |
| O02 | Métricas Linux via exporter | Targets UP e comparação com dados do host |
| O03 | Métricas Windows via exporter | Coletores/contas mínimos e comparação com servidor |
| O04 | Prometheus e regras | Configuração e regras verificadas antes de aplicar |
| O05 | Logs Linux com Alloy/Loki | Evento de teste chega com horário, host e serviço corretos |
| O06 | Logs Windows/Event Log | IDs e canais selecionados, sem captura irrestrita |
| O07 | Dashboards Grafana | Visão geral e diagnóstico, unidades e variáveis coerentes |
| O08 | Disponibilidade e TLS | Probes externos; distinguir falha de aplicação e de monitoramento |
| O09 | Alertas e notificações | Firing/resolved, agrupamento, silêncio e canal testados |
| O10 | AD, DNS, DFSR e Hyper-V | Métricas/eventos e permissões por função; backlog em tendência |
| O11 | Retenção e capacidade | Métricas/logs com limites de disco e crescimento medidos |
| O12 | Segurança da telemetria | Autenticação, rede restrita, TLS conforme topologia e dados sensíveis tratados |
| O13 | Agente de IA e triagem | Diagnóstico cita evidências, indica incerteza e não faz remediação automática |
| O14 | Tracing/OpenTelemetry | Instrumentar uma aplicação e correlacionar trace/log quando houver suporte |
| O15 | Backup da observabilidade | Recriar dashboards/regras e recuperar dados necessários |
| O16 | SLI/SLO e incidentes | Indicadores medidos, metas justificadas e revisão pós-incidente |

### Checklist observabilidade

- [ ] Inventariar o que já funciona nos projetos existentes antes de recriar.
- [ ] Definir topologia e responsabilidades: host, rede, aplicações e telemetria.
- [ ] Definir uma fonte de verdade para regras, dashboards e configurações.
- [ ] Implementar e testar O01–O04.
- [ ] Implementar e testar O05–O08.
- [ ] Implementar e testar O09–O12.
- [ ] Implementar e testar O13–O16.
- [ ] Usar Alloy/coletores suportados; avaliar ciclo de vida antes de escolher agentes.
- [ ] Evitar labels com usuário, URL completa ou identificadores de alta cardinalidade.
- [ ] Definir tratamento de segredos e dados pessoais nos logs.
- [ ] Evitar coleta duplicada por Alloy/OpenTelemetry em paralelo.
- [ ] Testar host offline, exporter offline e falha da aplicação como casos diferentes.
- [ ] Testar perda do Loki/Prometheus e canal de notificação indisponível.
- [ ] Confirmar recuperação e tempo de detecção em laboratório.
- [ ] Validar que o monitoramento percebe queda do host monitorado.
- [ ] Avaliar monitor externo quando observador e aplicação compartilham host.

## 5. Verificações automáticas do repositório — CI

- [ ] Markdown: estrutura e links locais.
- [ ] Bash: bash -n e ShellCheck.
- [ ] Formatação Bash com ferramenta definida e versão controlada.
- [ ] PowerShell: PSScriptAnalyzer.
- [ ] Testes relevantes de parsing, erro, timeout e relatórios.
- [ ] YAML/JSON: validação estrutural e exemplos sem segredos.
- [ ] Prometheus: promtool check config/rules e testes de regras.
- [ ] Configuração dos coletores validada com ferramenta da versão em uso.
- [ ] Scan de segredos com relatório controlado; triagem de falsos positivos.
- [ ] Dependências e imagens com versões/atualização planejadas.
- [ ] CI com menor privilégio e ações de terceiros revisadas.
- [ ] Não acessar AD, VPS ou AWS reais em testes de pull request.
- [ ] Não exibir relatórios internos como artefatos públicos.

## 6. Apresentação do GitHub — backlog de melhorias

- [ ] Perfil: destacar projetos públicos relevantes a Infra/DevOps/SRE.
- [ ] Trocar destaque de estudo privado por projeto público ou explicar indisponibilidade.
- [ ] Fixar projetos principais manualmente após escolher a vitrine.
- [ ] Escrever descrições curtas e adicionar topics coerentes.
- [ ] README: problema, solução, arquitetura, execução, evidências e limitações.
- [ ] Diagramas legíveis e screenshots com dados sanitizados.
- [ ] Remover instruções antigas e URLs de clone incorretas.
- [ ] Revisar arquivos gerados, caches, backups e exemplos de credenciais.
- [ ] Decidir se repositório duplicado deve ser identificado como histórico.
- [ ] Escolher licença conscientemente, considerando autoria e conteúdo de terceiros.
- [ ] Não renomear, arquivar ou apagar projetos sem avaliar impacto em links.
- [ ] Reavaliar o portfólio após as melhorias, com os mesmos critérios.

## 7. Próxima sequência de execução

1. L01/L04/L05: consolidar testes, corrigir limitações e registrar evidências.
2. L07: implementar consulta de rede com timeout e testes de falha.
3. Laboratório Linux: preparação → atualização → reboot → registro.
4. L09: backup e restauração demonstrados.
5. CI dos scripts e documentação.
6. Windows W01–W06, depois funções de domínio/Hyper-V.
7. Observabilidade: inventário existente → matriz → alertas → testes de falha.

## Critério para concluir uma entrega

- [ ] Procedimento revisado e ligado no índice.
- [ ] Script implementado, se previsto.
- [ ] Testes de sucesso e falha aprovados no ambiente declarado.
- [ ] Evidência registrada pelo modelo, sem dados sensíveis.
- [ ] Limitações e recuperação documentadas.
- [ ] Commit publicado e resultado conferido.

Este checklist é planejamento. Não representa implantação nem certificação de segurança.
