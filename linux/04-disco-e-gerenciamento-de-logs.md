# Runbook — Diagnóstico de disco e gerenciamento de logs

## Objetivo

Identificar consumo de armazenamento e controlar o crescimento
de logs sem excluir dados necessários às aplicações.

## Pré-requisitos

- Acesso sudo.
- Identificação dos discos e volumes das aplicações.
- Política de retenção de logs conhecida.
- Backup dos dados antes de qualquer exclusão necessária.

## Impacto

Consultas recursivas podem gerar carga de leitura no disco.
Excluir logs elimina histórico de diagnóstico e auditoria.
Excluir volumes pode destruir dados das aplicações.

## 1. Verificar espaço e inodes

```bash
df -hT
df -i
lsblk -f
```

Identificar o ponto de montagem afetado.
Verificar tanto espaço em bytes quanto disponibilidade de inodes.
Muitos arquivos pequenos podem esgotar inodes mesmo com espaço livre.

## 2. Localizar diretórios com maior consumo

```bash
sudo du -xhd1 / | sort -h
sudo du -xhd1 /var | sort -h
sudo du -xhd1 /var/log | sort -h
```

A opção -x mantém a análise no mesmo sistema de arquivos.
Analisar separadamente outros pontos de montagem.

Investigar primeiro o diretório responsável pelo crescimento.
Não excluir arquivos apenas porque são grandes.
Evitar varreduras repetidas em horários de maior utilização.

Diferenças entre df e du podem envolver arquivos apagados ainda
abertos, arquivos ocultos por montagens ou metadados do filesystem.

## 3. Conferir consumo do journal

```bash
sudo journalctl --disk-usage
```

Comparar consumo com o espaço disponível e a retenção necessária.
Preservar evidências de incidentes antes de limpar o histórico.

Exemplo de limpeza somente quando a retenção de sete dias
estiver aprovada:

```bash
sudo journalctl --rotate
sudo journalctl --vacuum-time=7d
```

A limpeza atua sobre arquivos arquivados.
O uso total ainda pode incluir arquivos ativos.
A exclusão não possui reversão sem uma cópia anterior.

Para controle contínuo, avaliar as configurações:

- SystemMaxUse: limite de uso para journal persistente.
- SystemKeepFree: espaço a preservar no filesystem.
- MaxRetentionSec: tempo máximo de retenção.

Definir valores conforme capacidade e necessidade operacional.
Validar mudanças no journald em uma manutenção específica.

## 4. Conferir rotação de logs

```bash
sudo logrotate --debug /etc/logrotate.conf
```

O modo debug não executa a rotação.
Inspecionar também as regras em /etc/logrotate.d/.

Verificar retenção, compressão, permissões e mecanismo de
reabertura dos logs pelo serviço.

Não truncar logs ativos nem forçar rotação sem avaliar o impacto.
Nem todo arquivo de log é gerenciado pelo logrotate.

## 5. Investigar arquivos excluídos ainda abertos

Quando lsof estiver instalado:

```bash
sudo lsof +L1
```

Identificar processo, tamanho e arquivo envolvidos.
Um processo pode continuar ocupando espaço de um arquivo excluído.

Avaliar reabertura de logs ou reinício controlado do serviço.
Não matar processos sem identificar dependências e impacto.

## 6. Conferir armazenamento Docker

Quando Docker estiver instalado:

```bash
sudo docker system df -v
sudo docker ps -a --size
```

Identificar imagens, containers, cache de build e volumes.
O tamanho gravável do container não representa todo o consumo
dos volumes e logs.

Antes de remover recursos, identificar aplicação responsável,
necessidade de recuperação e existência de backup.

Não usar docker system prune --volumes como limpeza genérica.
Não remover manualmente arquivos de /var/lib/docker.
Container parado não significa que seus dados são descartáveis.

Avaliar o driver de logs e a política de rotação.
Mudanças no padrão de logs podem exigir recriação de containers
para atingir os existentes; planejar isso separadamente.

## 7. Limpar cache APT quando apropriado

```bash
sudo apt clean
```

Remove pacotes baixados do cache, sem desinstalar aplicações.
Os pacotes precisarão ser baixados novamente se necessários.

A limpeza do cache não corrige crescimento contínuo de dados.
Não executar autoremove sem revisar os pacotes propostos.

## 8. Validar

```bash
df -hT
df -i
sudo journalctl --disk-usage
systemctl --failed
```

Comparar ocupação anterior e posterior.
Testar as aplicações que sofreram falta de espaço ou intervenção.
Investigar erros de escrita e possíveis efeitos sobre bancos.

## Critérios de conclusão

- Origem do consumo identificada.
- Espaço e inodes disponíveis para operação.
- Aplicações afetadas validadas.
- Retenção e prevenção de recorrência definidas.
- Exclusões e evidências registradas.

## Recuperação

Não existe reversão geral para exclusão de arquivos.
Restaurar dados somente a partir de cópias disponíveis.
Para mudanças de retenção, restaurar a configuração anterior;
isso não recupera logs já excluídos.

## Registro da execução

- Data e responsável:
- Filesystem afetado:
- Ocupação anterior e posterior:
- Diretórios responsáveis:
- Dados removidos e justificativa:
- Retenção aprovada:
- Validação das aplicações:
- Causa e prevenção:
