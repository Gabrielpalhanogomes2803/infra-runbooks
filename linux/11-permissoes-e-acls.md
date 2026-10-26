# Runbook — Arquivos, permissões e ACLs

## Objetivo e escopo
Diagnosticar acesso negado e conceder somente o acesso necessário. Exemplo de diretório compartilhado isolado; não aplicar recursivamente sobre árvores existentes sem inventário.

## Estado de validação
- Revisão documental: 26/10/2026.
- Alvo: Ubuntu Server com systemd; conferir versões e dependências locais.
- Execução em laboratório: pendente; nenhum comando foi executado na VPS por esta entrega.
- Substituir exemplos antes de executar. Blocos de alteração são condicionais.

## Pré-requisitos
- Sudo, usuário/grupo de serviço identificados e pacote acl para getfacl/setfacl.
- Conhecer caminho real e pontos de montagem.
- Preservar permissões atuais antes de mudanças.

## Impacto e condição para interromper
chmod, chown e ACLs podem expor segredos ou impedir execução. Não usar chmod -R 777 ou chown recursivo como correção genérica.

## 1. Diagnóstico — consulta
Adaptar caminho e conta:

```bash
id
namei -l /srv/app/arquivo
stat /srv/app/arquivo
getfacl -p /srv/app/arquivo
findmnt -T /srv/app/arquivo
```

Verificar todos os diretórios pais: travessia exige x.
Em diretório, r lista nomes, w permite alterações nas entradas e x permite travessia.
Excluir arquivo depende das permissões do diretório e de restrições como sticky bit, não só do arquivo.

## 2. Verificar identidade da aplicação

```bash
systemctl show nginx.service -p User -p Group
ps -eo user,group,pid,comm
```

Adaptar unidade. Alguns serviços iniciam master como root e workers como outro usuário.
Testar acesso efetivo sem abrir o conteúdo:

```bash
sudo -u www-data test -r /srv/app/arquivo
```

Saída zero indica teste verdadeiro. Falha não identifica sozinha qual camada bloqueou.
Conferir ACL mask, montagem ro/noexec, AppArmor e isolamento systemd quando os bits parecem corretos.

## 3. Preservar metadados — alteração local controlada
Exemplo para diretório pequeno já existente:

```bash
sudo install -d -m 700 /root/runbook-backups
sudo sh -c 'umask 077; getfacl -R -p /srv/app > /root/runbook-backups/app.acl'
```

O arquivo pode revelar nomes internos. Evitar varredura recursiva de árvores enormes.

## 4. Criar compartilhamento novo de laboratório
Somente se o grupo e diretório de laboratório ainda não existirem:

```bash
sudo groupadd labops
sudo install -d -o root -g labops -m 2770 /srv/lab-share
```

setgid no diretório faz novos itens herdarem o grupo; não garante escrita de grupo sozinho.
Adicionar somente usuário autorizado, substituindo operador:

```bash
sudo usermod -aG labops operador
```

Nova associação requer nova sessão. Usar grupo aprovado e não remover grupos anteriores.

## 5. ACL específica — alteração
Conceder leitura/travessia a uma conta existente no diretório de laboratório:

```bash
sudo setfacl -m u:operador:rx /srv/lab-share
getfacl -p /srv/lab-share
```

ACL pode recalcular mask e afetar acessos efetivos de outras entradas: revisar saída.
Para herança, definir ACL padrão somente após decidir a política:

```bash
sudo setfacl -m d:u:operador:rx /srv/lab-share
```

ACL padrão afeta novos itens; modo solicitado pela aplicação ainda limita permissões.
Não modifica retroativamente todos os arquivos.

## 6. Aceite
Testar com conta autorizada e outra não autorizada: listar, ler, criar e excluir conforme política.
Repetir para novos arquivos e subdiretórios. Conferir ACL mask e umask.
Não tornar chaves privadas ou arquivos de credenciais legíveis para ampliar acesso da aplicação.

## Recuperação
Para a árvore previamente capturada: sudo setfacl --restore=/root/runbook-backups/app.acl, revisando o escopo antes. Isso não recupera conteúdo removido nem permissões de itens criados depois. Remover apenas a associação/grupo de laboratório se não tiver dependências.

## Exercício de validação
Criar diretório e arquivo sem dados reais, demonstrar bloqueio e corrigir com grupo/ACL mínima. Comparar permissões anteriores e restauradas.

## Registro da execução
- Data, responsável e versão do sistema:
- Estado anterior e objetivo:
- Alterações e evidências sem segredos:
- Teste funcional e resultado:
- Recuperação e pendências:

## Referências
- https://man7.org/linux/man-pages/man5/acl.5.html
- https://man7.org/linux/man-pages/man1/setfacl.1.html
- https://www.gnu.org/software/coreutils/manual/html_node/File-permissions.html
