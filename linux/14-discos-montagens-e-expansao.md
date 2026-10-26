# Runbook — Discos, montagem persistente e expansão

## Objetivo e escopo
Inspecionar armazenamento, persistir uma montagem existente e expandir ext4 simples em laboratório. Não cobre redução, RAID, LUKS, LVM nem alteração do disco raiz em produção.

## Estado de validação
- Revisão documental: 26/10/2026.
- Alvo: Ubuntu Server com systemd; conferir versões e ferramentas.
- Execução em laboratório: pendente. Nenhuma alteração foi executada na VPS por esta entrega.
- Adaptar exemplos e executar mudanças somente nas condições descritas.

## Pré-requisitos
- Console e backup restaurável.
- Dispositivo identificado por tamanho, serial, UUID, filesystem e uso.
- Volume de laboratório já particionado/formatado e independente do disco do sistema.
- growpart disponível para o cenário de expansão simples.

## Impacto e condição para interromper
Dispositivo errado pode causar perda de dados e falha de boot. Parar se a topologia divergir do exemplo. Não executar mkfs, wipefs, dd ou reparticionamento como preparação deste procedimento.

## 1. Mapear todas as camadas — consulta

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,UUID,SERIAL
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
sudo blkid
df -hT
df -i
```

Distinguir disco, partição, filesystem e ponto de montagem.
Se TYPE mostrar LVM/crypt/raid, elaborar plano específico; não seguir expansão simples.

## 2. Montar volume existente no laboratório — alteração
Nos exemplos /dev/vdb1 deve ser substituído pelo volume confirmado.
O diretório de montagem deve estar vazio:

```bash
sudo install -d -m 755 /srv/lab-data
sudo ls -la /srv/lab-data
sudo mount /dev/vdb1 /srv/lab-data
findmnt --mountpoint /srv/lab-data
```

Montar sobre diretório com dados oculta o conteúdo anterior até desmontar.
Definir permissões após montar; a pasta vista antes pode ser do filesystem raiz.

## 3. Persistência por UUID — alteração

```bash
sudo cp -a /etc/fstab /etc/fstab.before-runbook
sudo blkid /dev/vdb1
sudo nano /etc/fstab
```

Não sobrescrever backup anterior: usar nome datado se já existir.
Exemplo de linha para ext4, substituir UUID:

```fstab
UUID=UUID_REAL /srv/lab-data ext4 defaults 0 2
```

Para disco opcional, avaliar nofail e timeout; não usá-los para esconder falha de volume crítico.
Aplicações devem recusar iniciar se o volume obrigatório não estiver montado, evitando gravar no disco raiz.

Validar:

```bash
sudo findmnt --verify --verbose
sudo systemctl daemon-reload
```

Somente no volume de laboratório, sem usuários/processos:

```bash
sudo umount /srv/lab-data
sudo mount /srv/lab-data
findmnt --mountpoint /srv/lab-data
```

Se ocupado, identificar consumidores; não usar umount -l/-f como atalho.
Reboot de validação somente após todos os testes e com console disponível.

## 4. Expandir ext4 simples — alteração em laboratório
Cenário exato: disco /dev/vdb com última partição /dev/vdb1 ext4, sem camadas adicionais.
Primeiro ampliar disco no provedor/hipervisor. Confirmar novo tamanho com lsblk.
Não continuar se o kernel ainda enxergar o tamanho antigo ou não houver espaço contíguo.

Simular mudança da partição:

```bash
sudo growpart -N /dev/vdb 1
```

Revisar início e novo final; não alterar início da partição.
Após backup e conferência:

```bash
sudo growpart /dev/vdb 1
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
```

Se a partição não mostrar o novo tamanho, parar e avaliar releitura/reboot.
Somente após confirmar ext4 e partição ampliada:

```bash
sudo resize2fs /dev/vdb1
df -hT /srv/lab-data
```

resize2fs expande o filesystem; não aumenta a partição.
Não executar e2fsck em filesystem montado.

## 5. Outras topologias
| Tipo | Tratamento |
|---|---|
| XFS | Ferramenta própria de crescimento sobre montagem; não usar resize2fs |
| LVM | Avaliar PV, espaço livre no VG, LV e filesystem |
| LUKS | Avaliar também camada criptografada e recuperação das chaves |
| Raiz/boot/EFI | Procedimento específico com console e plano de boot |

Não aplicar sequência de ext4 simples a essas topologias.

## 6. Aceite
Confirmar UUID, montagem, espaço e acesso pela conta da aplicação.
Testar criar/ler arquivo de laboratório e persistência após reboot planejado.
Comparar tamanho do disco, partição e filesystem: todas as camadas devem estar coerentes.

## Recuperação
Para erro em fstab, restaurar somente a linha alterada pelo console/rescue, validar e recarregar systemd. Expansão não tem reversão simples: não reduzir volume no provedor como rollback. Recuperar por backup em outro volume quando necessário.

## Exercício de validação
Anexar disco secundário descartável previamente preparado, persistir por UUID e ampliar. Registrar topologia antes/depois e leitura de um arquivo preservado. Nunca usar o disco raiz da VPS como exercício inicial.

## Registro da execução
- Data, responsável e versões:
- Estado anterior e objetivo:
- Arquivos, comandos e evidências sem segredos:
- Resultado funcional:
- Recuperação e pendências:

## Referências
- https://man7.org/linux/man-pages/man8/findmnt.8.html
- https://man7.org/linux/man-pages/man5/fstab.5.html
- https://github.com/canonical/cloud-utils/blob/main/man/growpart.1
- https://man7.org/linux/man-pages/man8/resize2fs.8.html
- https://man7.org/linux/man-pages/man8/xfs_growfs.8.html
