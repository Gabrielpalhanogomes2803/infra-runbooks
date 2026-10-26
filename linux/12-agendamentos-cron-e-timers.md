# Runbook — Agendamentos com cron e systemd timers

## Objetivo e escopo
Criar uma tarefa de laboratório com timer e diagnosticar cron. Para novos serviços em Ubuntu com systemd, o exemplo privilegia timers por integrarem estado e logs.

## Estado de validação
- Revisão documental: 26/10/2026.
- Alvo: Ubuntu Server com systemd; conferir versões e ferramentas.
- Execução em laboratório: pendente. Nenhuma alteração foi executada na VPS por esta entrega.
- Adaptar exemplos e executar mudanças somente nas condições descritas.

## Pré-requisitos
- Sudo para unidade do sistema e relógio sincronizado.
- Script previamente testado, sem prompts e com caminhos absolutos.
- Definir usuário, periodicidade, timeout e tratamento de falhas.

## Impacto e condição para interromper
Tarefa pode ser executada ao ativar Persistent=true após período inativo. Não agendar backup ou limpeza antes de testar manualmente. Não duplicar a mesma rotina em cron e timer.

## 1. Inventariar — consulta

```bash
timedatectl
systemctl list-timers --all --no-pager
crontab -l
sudo ls -l /etc/cron.d /etc/cron.daily
```

Ausência de crontab do usuário não exclui tarefas de outros usuários ou do sistema.
Quando cron estiver instalado:

```bash
systemctl status cron --no-pager
sudo journalctl -u cron --since '1 day ago' --no-pager
```


## 2. Serviço inofensivo de laboratório — alteração
Criar /etc/systemd/system/runbook-heartbeat.service:

```ini
[Unit]
Description=Registro de teste do runbook

[Service]
Type=oneshot
DynamicUser=yes
ExecStart=/usr/bin/logger -t runbook-heartbeat "timer executado"
TimeoutStartSec=30
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
```

Para backup real, usar identidade e acesso próprios; DynamicUser e proteções desse exemplo podem impedir acesso aos dados. Não remover proteções sem entender o motivo.

## 3. Timer — alteração
Criar /etc/systemd/system/runbook-heartbeat.timer:

```ini
[Unit]
Description=Agenda diaria do teste

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=5m

[Install]
WantedBy=timers.target
```

Horário segue o fuso do sistema. Persistent recupera uma ocorrência perdida, não todas.
RandomizedDelaySec adiciona atraso; não esperar execução exatamente às 03h00.
Se a mesma unidade ainda está ativa, o timer não inicia outra instância dela.
Isso não impede concorrência de outros caminhos de execução; usar lock quando necessário.

## 4. Validar e testar antes de habilitar

```bash
systemd-analyze calendar '*-*-* 03:00:00'
sudo systemd-analyze verify /etc/systemd/system/runbook-heartbeat.service /etc/systemd/system/runbook-heartbeat.timer
sudo systemctl daemon-reload
sudo systemctl start runbook-heartbeat.service
sudo journalctl -t runbook-heartbeat --since '10 minutes ago' --no-pager
```

Esperado: execução manual termina sem erro e mensagem aparece no journal.
Depois:

```bash
sudo systemctl enable --now runbook-heartbeat.timer
systemctl list-timers --all --no-pager
systemctl status runbook-heartbeat.timer --no-pager
```

Serviço oneshot pode voltar a inactive após sucesso; isso é esperado.
Monitorar falhas da tarefa e ausência de execução, não somente timer ativo.

## 5. Alternativa cron
Exemplo conceitual para crontab do usuário:

```cron
0 3 * * * /usr/bin/flock -n /CAMINHO_GRAVAVEL/tarefa.lock /CAMINHO_ABSOLUTO/tarefa.sh
```

Substituir ambos os caminhos e garantir diretório gravável para o usuário.
Crontab de usuário não tem campo de usuário; /etc/cron.d tem.
Cron usa ambiente reduzido. Declarar PATH, diretório de trabalho e destino dos logs.
O caractere % tem significado especial em comandos cron.
Não presumir que cron recupera execuções perdidas. Lock não adquirido precisa ser observável, pois a tarefa pode ser pulada.

## 6. Aceite
Confirmar calendário, execução manual, identidade efetiva, timeout e logs.
Testar retorno após indisponibilidade e alerta de tarefa atrasada.

## Recuperação
Desabilitar o timer: sudo systemctl disable --now runbook-heartbeat.timer. Isso não cancela uma tarefa já em execução; verificar o serviço. Remover somente os dois arquivos de laboratório e executar daemon-reload. Para cron, restaurar a crontab anterior.

## Exercício de validação
Usar calendário temporário curto em VM, observar duas execuções e depois desabilitar. Testar falha de serviço e recuperação de ocorrência perdida; restaurar a agenda original.

## Registro da execução
- Data, responsável e versões:
- Estado anterior e objetivo:
- Arquivos, comandos e evidências sem segredos:
- Resultado funcional:
- Recuperação e pendências:

## Referências
- https://freedesktop.org/software/systemd/man/latest/systemd.timer.html
- https://freedesktop.org/software/systemd/man/latest/systemd.service.html
- https://man7.org/linux/man-pages/man5/crontab.5.html
