# Runbook — Usuários administrativos e acesso SSH

## Objetivo

Configurar acesso administrativo individual por chave SSH,
com validação de acesso e procedimento de recuperação.

## Pré-requisitos

- Sessão administrativa aberta.
- Acesso ao console do provedor para recuperação.
- Chave pública do usuário.
- Usuário, privilégios e caminho de acesso definidos.
- Backup dos arquivos de configuração que serão alterados.

A chave privada deve permanecer no computador de origem.

## Impacto

Alterações incorretas podem impedir novas conexões.
Manter a sessão atual aberta até validar outro acesso.

## 1. Consultar o estado atual

```bash
whoami
id
getent group sudo
sudo /usr/sbin/sshd -t
sudo /usr/sbin/sshd -T
systemctl status ssh.service ssh.socket --no-pager
```

Conferir configuração, arquivos incluídos e regras Match.
sshd -T apresenta a configuração efetiva geral.
Regras Match precisam ser avaliadas para a conexão específica.

## 2. Criar usuário, quando necessário

Substituir operador pelo nome individual aprovado:

```bash
sudo adduser operador
sudo usermod -aG sudo operador
```

O grupo sudo concede administração ampla.
Adicionar somente quando esse privilégio for necessário.

Não usar contas compartilhadas para administração individual.
O grupo docker também concede controle elevado sobre o host.

## 3. Configurar a chave pública

Exemplo para usuário criado com home em /home/operador:

```bash
sudo install -d -m 700 -o operador -g operador /home/operador/.ssh
sudo -u operador nano /home/operador/.ssh/authorized_keys
sudo chown operador:operador /home/operador/.ssh/authorized_keys
sudo chmod 600 /home/operador/.ssh/authorized_keys
```

Inserir a chave pública completa em uma única linha.
Preservar chaves existentes que continuem autorizadas.
Nunca inserir chave privada nesse arquivo.

## 4. Testar uma nova conexão

No computador de origem, adaptar endereço e porta:

```bash
ssh operador@ENDERECO_DO_SERVIDOR
```

Na nova sessão:

```bash
id
sudo -v
```

Confirmar autenticação por chave e funcionamento do sudo.
Não restringir autenticação por senha antes desse teste.

## 5. Avaliar restrições de autenticação

Exemplo para um ambiente sem MFA interativo:

```text
PubkeyAuthentication yes
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
```

Estas diretivas devem ser avaliadas, não adicionadas às cegas.
Autenticação interativa pode ser necessária para MFA/PAM.

Identificar o arquivo correto e verificar precedência,
arquivos incluídos, regras Match e políticas do provedor.
Guardar cópia dos arquivos antes de modificá-los.

## 6. Validar e aplicar

Após editar, validar:

```bash
sudo /usr/sbin/sshd -t
sudo /usr/sbin/sshd -T
```

Resultado esperado: nenhuma falha de sintaxe e configuração
efetiva compatível com a política pretendida.

Para alteração de autenticação com ssh.service ativo:

```bash
sudo systemctl reload ssh.service
```

Mudança de porta, endereço ou ativação por socket exige
avaliação específica do serviço e do firewall.

Abrir outra conexão e testar chave e sudo novamente.
Manter a sessão original aberta até concluir.

## 7. Conferir caminho de rede

```bash
sudo ss -tulpn
sudo ufw status verbose
```

Consultar UFW somente quando instalado.
Conferir também firewall do provedor e regras da VPN.

Identificar se o acesso ocorre por rede pública ou Tailscale.
Porta em escuta não comprova acesso externo permitido.

## Critérios de conclusão

- Usuário possui somente os privilégios necessários.
- Nova conexão por chave validada.
- Sudo validado, quando autorizado.
- Configuração SSH validada.
- Caminho de recuperação disponível.
- Acesso repetido com sucesso após aplicar alterações.

## Recuperação

Usar a sessão original ou o console do provedor.
Restaurar exatamente os arquivos alterados.
Validar com sshd -t e reaplicar a configuração.
Testar nova conexão antes de encerrar a recuperação.

## Registro da execução

- Data e responsável:
- Usuário e privilégios:
- Impressão digital da chave pública:
- Arquivos alterados e cópias de recuperação:
- Caminho de acesso:
- Testes de conexão e sudo:
- Pendências:

