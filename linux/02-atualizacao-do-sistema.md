# Runbook — Atualização de pacotes Ubuntu

## Objetivo

Atualizar pacotes com avaliação de impacto e validação posterior.
Não cobre mudança de versão do Ubuntu nem atualização de containers.

## Pré-requisitos

- Acesso sudo e uma segunda sessão SSH.
- Console do provedor disponível para recuperação.
- Backup recente e procedimento de restauração conhecido.
- Aplicações e testes funcionais identificados.
- Janela de manutenção definida.

Snapshot não substitui backup consistente das aplicações e bancos.
Atualizações podem reiniciar serviços antes mesmo do reboot.

## 1. Registrar o estado anterior

```bash
date -Is
cat /etc/os-release
uname -r
uptime
df -h / /boot
df -i / /boot
systemctl --failed
sudo dpkg --audit
apt-mark showhold
```

Conferir espaço e inodes disponíveis.
Investigar pendências de instalação antes de continuar.
Registrar falhas existentes e motivos de pacotes retidos.

## 2. Conferir repositórios e atualizações

```bash
sudo find /etc/apt/sources.list.d -maxdepth 1 -type f \
  \( -name '*.list' -o -name '*.sources' \) -print
sudo apt update
apt list --upgradable
```

Revisar os arquivos de repositórios identificados e
/etc/apt/sources.list, quando existir.

Confirmar distribuição e fontes aprovadas.
Resolver erros de assinatura ou repositório antes de prosseguir.
apt update atualiza o índice; não instala atualizações.

## 3. Simular

```bash
sudo apt-get --simulate upgrade
```

Revisar o resumo e os pacotes mantidos na versão atual.
A simulação auxilia a revisão, mas não garante ausência de impacto.
Não executar full-upgrade automaticamente: pode remover pacotes.

## 4. Aplicar na janela de manutenção

```bash
sudo apt upgrade
```

Ler o resumo antes de confirmar.
Revisar diferenças de configuração antes de substituir arquivos.
Acompanhar a execução e registrar avisos ou erros.

## 5. Verificar instalação e necessidade de reboot

```bash
sudo dpkg --audit
sudo apt-get check
systemctl --failed
sudo tail -n 80 /var/log/apt/history.log
if [ -f /var/run/reboot-required ]; then
  cat /var/run/reboot-required
  if [ -f /var/run/reboot-required.pkgs ]; then
    cat /var/run/reboot-required.pkgs
  fi
fi
```

Investigar erros e comparar com o estado anterior.
A ausência de reboot-required não garante que todos os processos
estejam usando as bibliotecas atualizadas.

## 6. Reiniciar quando necessário

Confirmar acesso ao console, persistência dos dados e
inicialização automática dos serviços necessários.

Quando houver Docker, conferir previamente quais containers
devem retornar e suas políticas de reinício.

Na janela planejada:

```bash
sudo reboot
```

A sessão SSH será interrompida. Aguardar e reconectar.

## 7. Validar depois

```bash
uptime
uname -r
systemctl is-system-running
systemctl --failed
sudo journalctl -b -p err --no-pager -n 50
```

Quando houver Docker:

```bash
sudo docker ps -a
```

Testar URLs, autenticação e operações principais.
Comparar com o estado anterior.
Serviço ativo não comprova aplicação saudável.

## Recuperação

Usar o console se o SSH não retornar.
Identificar a mudança antes de tentar correções.
Avaliar kernel anterior quando aplicável e disponível.
Restaurar configurações ou backups conforme o problema.

APT não oferece rollback transacional geral.
Restaurar snapshot pode perder dados posteriores à sua criação.

## Registro da execução

- Data e responsável:
- Backup e recuperação:
- Estado anterior:
- Pacotes alterados:
- Decisões sobre configurações:
- Reinicialização:
- Testes funcionais:
- Pendências:
