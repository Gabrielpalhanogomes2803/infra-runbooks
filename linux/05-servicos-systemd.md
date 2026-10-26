# Runbook — Operação e diagnóstico de serviços systemd

## Objetivo

Identificar falhas, consultar logs e executar ações controladas
em serviços, com validação do funcionamento da aplicação.

## Pré-requisitos

- Acesso sudo para ações administrativas.
- Nome da unidade confirmado.
- Dependências e impacto da interrupção conhecidos.
- Configuração anterior preservada antes de alterações.
- Teste funcional da aplicação definido.

## Impacto

Reiniciar ou parar serviços pode interromper aplicações.
Iniciar um serviço pode executar tarefas e processar dados.
Recarregar depende do suporte da aplicação e pode afetar conexões.

## 1. Identificar a unidade

```bash
systemctl list-units --type=service --all --no-pager
systemctl list-unit-files --type=service --no-pager
systemctl --failed
```

list-units mostra unidades carregadas.
list-unit-files lista arquivos de unidade conhecidos.

Definir a unidade investigada. Exemplo para Nginx:

```bash
UNIT=nginx.service
```

Substituir pelo serviço correto antes dos próximos comandos.
A variável vale para a sessão atual do terminal.

## 2. Consultar estado e inicialização

```bash
systemctl status "$UNIT" --no-pager -l
systemctl is-active "$UNIT"
systemctl is-enabled "$UNIT"
```

active indica o estado atual, mas não garante aplicação saudável.
enabled indica configuração de ativação na inicialização.

Serviços podem estar ativos sem estarem habilitados.
Unidades static podem ser iniciadas por dependências.
Sockets e timers também podem ativar serviços.

Uma resposta não ativa pode produzir código de saída diferente
de zero; interpretar o resultado antes de concluir falha.

## 3. Consultar logs

```bash
sudo journalctl -u "$UNIT" -b --no-pager -n 100
sudo journalctl -u "$UNIT" --since "30 minutes ago" --no-pager
```

Correlacionar erros com horário do incidente e mudanças recentes.
Verificar também logs próprios da aplicação, quando existirem.
Ausência de registros no journal não comprova ausência de erros.

## 4. Consultar configuração e dependências

```bash
systemctl cat "$UNIT"
systemctl list-dependencies "$UNIT"
systemctl list-dependencies --reverse "$UNIT"
systemctl show "$UNIT" \
  -p Result \
  -p ExecMainCode \
  -p ExecMainStatus \
  -p NRestarts
```

Verificar comando de execução, usuário, diretório de trabalho,
arquivos de ambiente e política de reinício.

Não publicar segredos encontrados na configuração.
Dependências do systemd não representam todas as dependências
externas, como banco, DNS ou APIs.

NRestarts ajuda a investigar reinícios automáticos, mas não
representa um histórico completo de todas as reinicializações.

## 5. Escolher a ação necessária

Executar somente a ação apropriada ao diagnóstico.

| Ação | Comando | Efeito |
|---|---|---|
| Iniciar | sudo systemctl start "$UNIT" | Inicia a unidade |
| Parar | sudo systemctl stop "$UNIT" | Interrompe a unidade |
| Reiniciar | sudo systemctl restart "$UNIT" | Para e inicia; inicia se estava parada |
| Recarregar | sudo systemctl reload "$UNIT" | Solicita recarga, quando suportada |
| Habilitar | sudo systemctl enable "$UNIT" | Configura ativação na inicialização |
| Desabilitar | sudo systemctl disable "$UNIT" | Remove habilitação, sem parar |

enable não inicia imediatamente sem --now.
disable não impede ativação por dependências ou outros mecanismos.

Não repetir restart sem investigar a causa.
Antes de aplicar mudanças, usar o validador da aplicação.

Exemplo para Nginx:

```bash
sudo nginx -t
```

Prosseguir somente se a validação for bem-sucedida.

## 6. Alterar uma unidade quando necessário

Preservar a configuração anterior e registrar os arquivos alterados.
Preferir um override a editar o arquivo fornecido pelo pacote:

```bash
sudo systemctl edit "$UNIT"
```

Após salvar alterações na definição da unidade:

```bash
sudo systemctl daemon-reload
systemctl cat "$UNIT"
```

daemon-reload recarrega definições do systemd.
Ele não reinicia a aplicação nem equivale a reload do serviço.

Avaliar separadamente se a alteração exige restart.
Alterações apenas na configuração da aplicação normalmente
seguem o procedimento próprio dela.

## 7. Validar a intervenção

```bash
systemctl status "$UNIT" --no-pager -l
sudo journalctl -u "$UNIT" --since "5 minutes ago" --no-pager
systemctl --failed
```

Executar o teste funcional definido para a aplicação:
resposta HTTP, consulta ao banco ou processamento de tarefa.

Comparar com o estado anterior.
Observar se a falha reaparece ou o serviço reinicia repetidamente.

## Critérios de conclusão

- Estado da unidade interpretado.
- Causa identificada ou pendência documentada.
- Alterações e ações registradas.
- Teste funcional concluído.
- Ausência de novas falhas relacionadas durante a observação.

## Recuperação

Restaurar exatamente a configuração alterada.
Se houve mudança de unidade, executar daemon-reload.
Validar a configuração da aplicação antes de reaplicar a ação.

Não remover todos os overrides para desfazer uma única alteração.
Não usar systemctl revert sem avaliar os arquivos que ele removerá.

reset-failed limpa o estado de falha e contadores associados;
não corrige a causa do problema.

## Registro da execução

- Data e responsável:
- Unidade:
- Sintomas e horário:
- Evidências:
- Causa ou hipótese:
- Arquivos alterados:
- Ação executada:
- Teste funcional:
- Recuperação e pendências:
