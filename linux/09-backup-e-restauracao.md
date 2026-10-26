# Runbook — Backup e restauração com restic

## Objetivo e escopo
Criar backup de arquivos e demonstrar recuperação isolada. Não substitui backup consistente de bancos, AD ou snapshots coordenados de aplicações.

## Estado de validação
- Revisão documental: 26/10/2026.
- Alvo: Ubuntu Server com systemd; conferir versões e dependências locais.
- Execução em laboratório: pendente; nenhum comando foi executado na VPS por esta entrega.
- Substituir exemplos antes de executar. Blocos de alteração são condicionais.

## Pré-requisitos
- Restic instalado por fonte aprovada e versão registrada.
- Destino independente do disco/host protegido; credenciais com menor privilégio.
- Definir RPO, RTO, retenção, capacidade e responsável.
- Local seguro para senha do repositório, fora do Git e recuperável mesmo se o host falhar.

## Impacto e condição para interromper
Backup e verificação consomem I/O, rede e armazenamento. Restauração pode sobrescrever dados se feita no destino de produção. Interromper se o destino remoto não estiver montado ou se não houver espaço.

## 1. Preparar credenciais — alteração

```bash
sudo install -d -m 700 /root/.config/restic
sudo nano /root/.config/restic/password
sudo chmod 600 /root/.config/restic/password
```

Inserir uma senha forte e preservar uma cópia em cofre separado.
Não colocar senha no comando, histórico, README ou variável versionada.

## 2. Selecionar destino
Neste exemplo /mnt/backup é um armazenamento independente já montado.

```bash
findmnt --mountpoint /mnt/backup
df -h /mnt/backup
restic version
```

Se findmnt não confirmar a montagem exata, parar. Não gravar silenciosamente no disco raiz.
Inicializar SOMENTE um repositório novo; não reinicializar o existente:

```bash
sudo restic -r /mnt/backup/restic --password-file /root/.config/restic/password init
```

Para SFTP/S3, adaptar backend, autenticação e política conforme documentação.

## 3. Definir dados consistentes
Inventariar configuração, arquivos, ACLs, proprietários e segredos necessários.
Não copiar diretório de banco em execução como se fosse backup consistente.
Usar dump/backup nativo e procedimento próprio de restauração.
O exemplo abaixo inclui apenas /etc e /srv/dados; confirmar existência e conteúdo.
Logs, caches e caminhos de retenção devem ser deliberados.

## 4. Criar backup — grava no destino

```bash
sudo restic -r /mnt/backup/restic --password-file /root/.config/restic/password backup /etc /srv/dados --tag linux-files
sudo restic -r /mnt/backup/restic --password-file /root/.config/restic/password snapshots
```

Verificar código de saída e arquivos não lidos. Snapshot criado não significa todos os arquivos copiados.
Registrar ID exato do snapshot, host e caminhos.

## 5. Verificar integridade

```bash
sudo restic -r /mnt/backup/restic --password-file /root/.config/restic/password check
```

check padrão não lê todo o conteúdo dos dados. Planejar leitura completa ou amostragem periódica:

```bash
sudo restic -r /mnt/backup/restic --password-file /root/.config/restic/password check --read-data
```

Pode ser demorado e gerar cobrança de leitura no backend.

## 6. Restaurar em diretório isolado — alteração
Substituir SNAPSHOT_ID pelo ID registrado. Garantir que o destino está vazio e com espaço:

```bash
sudo install -d -m 700 /var/tmp/restore-lab
sudo restic -r /mnt/backup/restic --password-file /root/.config/restic/password restore SNAPSHOT_ID --target /var/tmp/restore-lab
```

Arquivos voltam com sua hierarquia, como /var/tmp/restore-lab/etc.
Comparar um arquivo estável com sha256sum/cmp e conferir permissões com stat/getfacl.
Nunca restaurar /etc inteiro sobre um host ativo como teste.
Validar a aplicação em ambiente isolado e medir tempo real de recuperação.

## 7. Retenção — primeiro simular
Exemplo a adaptar à política:

```bash
sudo restic -r /mnt/backup/restic --password-file /root/.config/restic/password forget --tag linux-files --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --dry-run
```

Revisar agrupamento por host/caminho e todos os snapshots selecionados.
Somente depois aprovar forget sem dry-run e prune em manutenção própria.
Exclusão é irreversível sem outra cópia. Não incluir a execução destrutiva em agendamento sem revisão.

## 8. Agendamento e aceite
Associar ao runbook de timers: credenciais sem prompt, destino verificado,
monitoramento de falha e de backup atrasado. Testar restauração periodicamente.
Aceite: snapshot sem erros, cópia externa acessível, integridade e restauração demonstradas.

## Recuperação
Backup falho: preservar cópias anteriores e corrigir acesso/capacidade antes de repetir. Restauração de produção exige plano para parar aplicação, guardar estado atual e restaurar dados consistentes. Perda da senha/chave pode tornar o repositório irrecuperável.

## Exercício de validação
Alterar e recuperar um arquivo de teste em destino isolado; comparar conteúdo e permissões. Simular destino desmontado e garantir que a rotina falha sem gravar no disco local.

## Registro da execução
- Data, responsável e versão do sistema:
- Estado anterior e objetivo:
- Alterações e evidências sem segredos:
- Teste funcional e resultado:
- Recuperação e pendências:

## Referências
- https://restic.readthedocs.io/en/stable/040_backup.html
- https://restic.readthedocs.io/en/stable/050_restore.html
- https://restic.readthedocs.io/en/stable/060_forget.html
