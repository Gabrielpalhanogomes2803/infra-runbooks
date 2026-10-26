# Runbook — Revisão de segurança e auditoria

## Objetivo e escopo
Revisar acessos, serviços, correções e proteção básica. É uma revisão operacional, não certificação de conformidade nem investigação forense completa.

## Estado de validação
- Revisão documental: 26/10/2026.
- Alvo: Ubuntu Server com systemd; conferir versões e ferramentas.
- Execução em laboratório: pendente. Nenhuma alteração foi executada na VPS por esta entrega.
- Adaptar exemplos e executar mudanças somente nas condições descritas.

## Pré-requisitos
- Sudo, inventário de contas, serviços necessários e política de atualização.
- Autorização para revisar logs; preservar dados pessoais e evidências.
- Ler os procedimentos de SSH, firewall, backup e atualização.

## Impacto e condição para interromper
Contenção, bloqueio de conta ou atualização pode interromper operação. Se houver suspeita de comprometimento ativo, preservar evidências e seguir resposta a incidente; não limpar logs nem executar correções indiscriminadas.

## 1. Contas e privilégios — consulta

```bash
getent passwd
getent group sudo
sudo visudo -c
sudo ls -l /etc/sudoers.d
last -n 20
```

Inventariar contas humanas, técnicas e chaves autorizadas. Não classificar conta como indevida só pelo nome ou UID.
Conferir privilégios indiretos, como grupo docker, sudoers e acesso ao socket Docker.
last depende dos registros disponíveis e não é evidência completa.
Não exibir /etc/shadow ou conteúdo de chaves privadas.

## 2. Autenticação e acesso — consulta

```bash
sudo /usr/sbin/sshd -t
sudo /usr/sbin/sshd -T
sudo journalctl -u ssh.service --since '24 hours ago' --no-pager
sudo journalctl _COMM=sshd-session --since '24 hours ago' --no-pager
```

Unidades/processos variam conforme versão; complementar com registros de autenticação existentes.
Correlacionar sucesso/falha, origem e horário com atividades autorizadas.
Teste uma nova conexão antes de alterar política; seguir o runbook SSH.

## 3. Superfície de exposição — consulta

```bash
sudo ss -tulpn
systemctl list-unit-files --type=service --state=enabled --no-pager
sudo ufw status verbose
```

Serviço habilitado não significa necessariamente porta pública.
Revisar serviços, sockets, containers, IPv6, proxy e firewall do provedor.
Desabilitar somente unidade dispensável após mapear dependências e preservar estado anterior.

## 4. Atualizações e automação — consulta/simulação

```bash
sudo apt update
apt list --upgradable
apt-cache policy unattended-upgrades
systemctl list-timers --all --no-pager
apt-config dump | grep -Ei 'APT::Periodic|Unattended-Upgrade'
```

A configuração varia por imagem e versão; não presumir que existe ou está ativa.
Se unattended-upgrades estiver instalado, em janela adequada:

```bash
sudo unattended-upgrade --dry-run --debug
```

Revisar origens permitidas, pacotes excluídos, logs, necessidade de reinício e responsáveis.
Dry-run não substitui teste de atualização/reboot; não habilitar reboot automático sem política.

Para configurar, preservar arquivos e usar drop-in local em /etc/apt/apt.conf.d,
sem sobrescrever configurações do pacote. Definir explicitamente janela, logs e reinicialização.
Conferir também snap, containers e pacotes externos: APT não atualiza tudo.
Aplicar atualizações pelo runbook específico.

## 5. Confinamento e segredos — consulta
Quando AppArmor estiver instalado:

```bash
sudo aa-status
sudo journalctl -k --since '24 hours ago' --no-pager | grep -i apparmor
```

Não desabilitar AppArmor para esconder erro de permissão: revisar perfil e caminho negado.
Inventariar localização e permissões de .env, credenciais de backup e chaves.
Evitar varreduras que imprimam o conteúdo desses arquivos.
Retirar segredo do Git não basta se foi publicado: revogar/rotacionar e tratar o histórico.

## 6. Auditoria contínua
Se auditd for exigido, definir primeiro eventos e retenção com o responsável.
Não habilitar regras amplas de auditoria sobre todo o filesystem sem avaliar volume.
Preferir regras específicas, versão controlada sem segredos e teste de eventos.
Encaminhar eventos críticos para destino externo protegido quando necessário.

## 7. Aceite e priorização
Registrar achado, evidência, impacto, ação, dono e prazo.
Confirmar acesso por chave, restauração disponível, portas intencionais e política de patches.
Repetir teste externo e funcional após qualquer correção.
Nenhum achado numa revisão limitada não significa ausência de vulnerabilidades.

## Recuperação
Restaurar configurações alteradas e testar acesso pelo console. Reativar somente serviços necessários. Se uma credencial foi comprometida, não restaurar a credencial antiga: revogar e substituir. Em incidente, priorizar preservação e contenção coordenada.

## Exercício de validação
Em VM, detectar uma conta de teste com privilégio indevido, um serviço desnecessário e uma permissão insegura em arquivo fictício. Corrigir e produzir registro sanitizado, sem simular ataque na VPS.

## Registro da execução
- Data, responsável e versões:
- Estado anterior e objetivo:
- Arquivos, comandos e evidências sem segredos:
- Resultado funcional:
- Recuperação e pendências:

## Referências
- https://ubuntu.com/server/docs/explanation/security/security_suggestions/
- https://ubuntu.com/server/docs/how-to/software/automatic-updates/
- https://ubuntu.com/server/docs/openssh-server/
- https://documentation.ubuntu.com/security/security-updates/
