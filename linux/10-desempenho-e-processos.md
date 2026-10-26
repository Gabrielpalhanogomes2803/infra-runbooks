# Runbook — CPU, memória e processos

## Objetivo e escopo
Diagnosticar lentidão com amostras e correlação. Evitar ajustes de kernel e encerramentos de processos sem causa identificada.

## Estado de validação
- Revisão documental: 26/10/2026.
- Alvo: Ubuntu Server com systemd; conferir versões e dependências locais.
- Execução em laboratório: pendente; nenhum comando foi executado na VPS por esta entrega.
- Substituir exemplos antes de executar. Blocos de alteração são condicionais.

## Pré-requisitos
- Acesso às métricas e horário do incidente.
- procps; sysstat para mpstat/iostat/pidstat, quando necessário.
- Conhecer vCPUs, limites de containers e comportamento normal.

## Impacto e condição para interromper
Consultas são de baixo impacto, mas varreduras e ferramentas adicionais têm custo. Não executar carga sintética ou stress em produção sem planejamento.

## 1. Coletar contexto — consulta

```bash
date -Is
uptime
nproc
free -h
swapon --show
vmstat 1 5
```

Ignorar a primeira linha de vmstat na análise instantânea: costuma representar médias desde o boot.
Load inclui tarefas executando/aguardando CPU e tarefas em espera ininterruptível.
Comparar com vCPUs e baseline; load alto não equivale automaticamente a CPU saturada.
Memória available é mais útil do que free isoladamente. Swap ocupada não comprova pressão atual.
Observar si/so sustentados, espera e tendências.

## 2. Identificar processos — consulta

```bash
ps -eo pid,ppid,user,stat,%cpu,%mem,rss,comm --sort=-%cpu | head -n 16
ps -eo pid,ppid,user,stat,%cpu,%mem,rss,comm --sort=-rss | head -n 16
top
```

ps fornece uma visão diferente das amostras instantâneas do top; RSS está em KiB.
Evitar compartilhar argumentos completos de processos que possam conter segredos.

## 3. Detalhar CPU e I/O com sysstat

```bash
mpstat -P ALL 1 5
iostat -xz 1 5
pidstat -u -r -d 1 5
```

Correlacionar latência, fila, CPU, steal em VM e aplicação.
%util isolado não mede saturação de todos os tipos de disco.
Não concluir que ampliar memória resolve gargalo de CPU, armazenamento ou dependência externa.

## 4. Procurar pressão e OOM

```bash
cat /proc/pressure/cpu
cat /proc/pressure/memory
cat /proc/pressure/io
sudo journalctl -k --since '1 hour ago' --no-pager | grep -Ei 'out of memory|oom|killed process'
```

PSI pode não existir em todos os kernels. Ausência de correspondência no grep não prova ausência histórica.
Se systemd-oomd for usado, consultar seus logs separadamente.
Com Docker:

```bash
sudo docker stats --no-stream
sudo docker inspect NOME_DO_CONTAINER --format 'OOM={{.State.OOMKilled}} Exit={{.State.ExitCode}} MemoryLimit={{.HostConfig.Memory}}'
```

Substituir o nome. Limite de memória zero nessa configuração normalmente indica ausência de limite explícito do container; limites superiores de cgroup ainda podem existir.
Código 137 indica SIGKILL, não confirma OOM.

## 5. Mitigação — alteração condicional
Identificar dono do processo, dependências, impacto e forma de parada graciosa.
Preferir operação documentada da aplicação ou systemctl stop ao encerramento por PID.
Se necessário, após confirmar o PID atual:

```bash
kill -TERM PID_CONFIRMADO
```

Não copiar o placeholder literalmente. SIGKILL é último recurso e pode impedir limpeza.
Não desabilitar swap, limpar caches nem alterar sysctl como solução genérica.

## 6. Aceite
Repetir amostras, testar aplicação e comparar latência/erros com baseline.
Registrar causa, janela, métricas e solução; não apenas redução momentânea de CPU.

## Recuperação
Reverter somente limites/configurações alterados e reiniciar de forma controlada quando aplicável. Se houve OOM, preservar logs antes de modificar capacidade. Encerrar processo não é reversível; avaliar consistência dos dados.

## Exercício de validação
Em VM limitada, observar carga controlada por curto período com ferramenta apropriada. Demonstrar diferença entre CPU alta, memória disponível e pressão. Não provocar OOM na VPS compartilhada.

## Registro da execução
- Data, responsável e versão do sistema:
- Estado anterior e objetivo:
- Alterações e evidências sem segredos:
- Teste funcional e resultado:
- Recuperação e pendências:

## Referências
- https://www.kernel.org/doc/html/latest/admin-guide/mm/concepts.html
- https://www.kernel.org/doc/html/latest/accounting/psi.html
- https://sysstat.github.io/
