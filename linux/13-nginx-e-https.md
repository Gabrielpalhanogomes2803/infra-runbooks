# Runbook — Nginx, proxy reverso e HTTPS

## Objetivo e escopo
Configurar proxy de laboratório e validar TLS/renovação. Não publicar dashboards ou APIs sem autenticação apropriada.

## Estado de validação
- Revisão documental: 26/10/2026.
- Alvo: Ubuntu Server com systemd; conferir versões e ferramentas.
- Execução em laboratório: pendente. Nenhuma alteração foi executada na VPS por esta entrega.
- Adaptar exemplos e executar mudanças somente nas condições descritas.

## Pré-requisitos
- Nginx instalado por fonte aprovada; sudo e configuração anterior preservada.
- Backend existente em loopback, porta conhecida e endpoint funcional.
- Domínio sob controle, DNS A/AAAA corretos e portas conforme desafio ACME.
- Escolher uma instalação suportada do Certbot; não misturar apt e snap.

## Impacto e condição para interromper
Configuração pode alterar rotas e exposição pública. Certbot com plugin nginx modifica configuração. Parar se nginx -t falhar, backend estiver indisponível ou DNS apontar para origem errada.

## 1. Diagnóstico — consulta

```bash
sudo nginx -t
systemctl status nginx --no-pager
sudo ss -tulpn
curl --connect-timeout 5 --max-time 15 http://127.0.0.1:8000/
```

8000 é exemplo; adaptar ao backend. Confirmar resposta e conteúdo esperado.
Inspecionar configuração efetiva com sudo nginx -T em local restrito; ela pode conter informações internas.

## 2. Proxy HTTP de laboratório — alteração
Em instalação Ubuntu que inclui sites-enabled, criar arquivo próprio em sites-available,
preservando os sites existentes. Exemplo a adaptar:

```nginx
server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 5s;
        proxy_read_timeout 60s;
    }
}
```

Não usar domínio de exemplo em emissão real.
proxy_pass sem URI preserva o caminho recebido; adicionar barra/caminho muda o mapeamento.
A aplicação deve confiar em cabeçalhos de proxy apenas das origens controladas.
Se houver CDN, não confiar cegamente em IP enviado pelo cliente.
WebSocket exige configuração adicional; não presumir suporte neste exemplo.

Habilitar somente o arquivo novo, adaptando seu nome:

```bash
sudo ln -s /etc/nginx/sites-available/app-lab /etc/nginx/sites-enabled/app-lab
sudo nginx -t
```

Se o link já existe, inspecionar; não sobrescrever.
Somente após validação:

```bash
sudo systemctl reload nginx
curl -I -H 'Host: app.example.com' http://127.0.0.1/
```

Esse teste local não comprova DNS público nem acesso externo.

## 3. Emitir HTTPS — alteração condicional
Antes, testar DNS e acesso ao domínio real. HTTP-01 normalmente precisa de porta 80 pública;
DNS-01 exige controle DNS e é necessário para wildcard.
Com Certbot e plugin nginx disponíveis:

```bash
sudo certbot --nginx -d DOMINIO_REAL
```

Substituir o domínio e revisar alterações. Não repetir pedidos indiscriminadamente por limites da autoridade.
Credenciais DNS, quando usadas, devem ficar fora do Git e restritas.

## 4. Verificar TLS e renovação

```bash
sudo certbot certificates
sudo nginx -t
systemctl list-timers --all --no-pager
```

Com o domínio real:

```bash
curl -I --connect-timeout 5 --max-time 15 https://DOMINIO_REAL/
sudo certbot renew --dry-run
```

dry-run usa ambiente de teste para renovação e pode executar hooks relacionados;
planejar seu impacto. Identificar cron/timer da instalação em uso e verificar logs.
Não basta emitir o certificado: confirmar recarga e monitorar validade externamente.
Não adicionar HSTS de longa duração antes de validar toda a política HTTPS.

## 5. Diagnóstico por sintoma
| Sintoma | Investigar |
|---|---|
| 502 | Backend parado, porta ou protocolo incorretos, permissões |
| 504 | Lentidão/timeout do backend ou dependências |
| 404 | server_name, location, caminho encaminhado e rota da aplicação |
| TLS inválido | Domínio, cadeia, validade, SNI e configuração ativa |
| Erro só em IPv6 | Registro AAAA, rota, listen e firewall |
| Renovação falha | DNS, desafio, acesso público, credenciais e logs |

Consultar access/error logs configurados e journal, sem publicar tokens/URLs sensíveis.

## 6. Aceite
Testar de outra máquina: DNS, HTTP/HTTPS, redirecionamento, conteúdo e operação da aplicação.
Verificar que o backend não ficou exposto diretamente e que a renovação de teste funciona.

## Recuperação
Restaurar o site e demais arquivos modificados, validar nginx -t e recarregar. Preservar certificados existentes; não apagar /etc/letsencrypt para desfazer configuração. Certbot pode alterar mais de um arquivo: comparar com backup.

## Exercício de validação
Publicar aplicação sem dados sensíveis, testar rota correta e backend parado, recuperar e validar HTTPS/renovação. Registrar respostas e validade sem chaves privadas.

## Registro da execução
- Data, responsável e versões:
- Estado anterior e objetivo:
- Arquivos, comandos e evidências sem segredos:
- Resultado funcional:
- Recuperação e pendências:

## Referências
- https://nginx.org/en/docs/beginners_guide.html
- https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- https://eff-certbot.readthedocs.io/en/stable/using.html
