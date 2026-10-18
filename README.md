# SKYNET TF2 Zombie Infection (Docker)

Servidor de **TF2 Zombie Infection** pronto para usar: os 6 mapas `zi_` oficiais da Valve, rotação e configurações do modo, em cima da imagem [`tf2-sourcemod`](https://github.com/melkortf/tf2-servers) do melkor.tf. A imagem base não traz esses mapas; aqui eles são baixados direto da Steam durante a montagem.

```
ghcr.io/luci-immerstark/skynet-tf2-zombie:latest
```

[English below](#english)

## Começo rápido

1. Crie um arquivo `zombie.env` (só você deve conseguir ler: `chmod 600 zombie.env`):

   ```
   RCON_PASSWORD=<gere com: openssl rand -hex 16>
   SERVER_HOSTNAME=Meu Servidor de Zombie Infection
   SERVER_TOKEN=<seu token GSLT>
   SM_ADMINS=<seu SteamID, ex.: STEAM_0:1:1234567>
   ```

2. Ligue o servidor:

   ```bash
   docker run -d --name tf2-zombie --restart unless-stopped \
     --env-file zombie.env \
     -p 27015:27015/udp \
     ghcr.io/luci-immerstark/skynet-tf2-zombie:latest
   ```

   Na primeira vez ele confere atualizações do TF2 e pode levar alguns minutos para aparecer.

3. Entre pelo console do jogo: `connect SEU_IP:27015`.

Com `docker compose`:

```yaml
services:
  zombie:
    image: ghcr.io/luci-immerstark/skynet-tf2-zombie:latest
    restart: unless-stopped
    env_file: zombie.env
    ports:
      - "27015:27015/udp"
```

## Variáveis

| Variável | Padrão | Para que serve |
|---|---|---|
| `RCON_PASSWORD` | (vazia) | **Obrigatória.** Senha do RCON: no mínimo 12 caracteres, só letras, números e `. _ - @ % + =`. Sem ela, ou com senha fraca, o servidor não liga. |
| `SERVER_HOSTNAME` | `TF2 Zombie Infection Server` | Nome do servidor na lista. |
| `SERVER_PASSWORD` | (vazia) | Senha para entrar no servidor (vazia = aberto). |
| `SERVER_TOKEN` | (vazio) | Token GSLT, para o servidor aparecer na lista da Steam. Crie em <https://steamcommunity.com/dev/managegameservers> (App ID 440). |
| `SM_ADMINS` | (vazio) | SteamIDs dos admins, separados por vírgula (`STEAM_0:1:123` ou `[U:1:123]`). Recebem acesso total (`z`). |
| `SERVER_TAGS` | `zombie,infection,zi` | Tags do servidor. |
| `SERVER_REGION` | `255` | Região (`0` a `7`, `255` = mundo; `2` = América do Sul). |
| `PORT` | `27015` | Porta do jogo (publique a mesma no `-p`). |
| `TICKRATE` | (vazio = 66,7) | `100`, `133` ou `200`, da imagem base. |

Nomes, senhas e links não podem ter aspas, ponto e vírgula ou quebra de linha (é assim que se injetaria comando no `server.cfg`); a imagem recusa.

## O que vem dentro

- **Mapas oficiais**: zi_atoll, zi_blazehattan, zi_devastation_final1, zi_murky, zi_sanitarium e zi_woods, baixados da Steam (servidor dedicado do TF2, login anônimo) com o [DepotDownloader](https://github.com/SteamRE/DepotDownloader) em versão e checksum fixos. Ele só roda na montagem e não fica na imagem.
- **O modo** vem dentro dos próprios mapas e cuida dos times sozinho; a imagem só desliga o balanceamento automático.
- **Configuração**: 30 minutos por mapa, rotação pelos 6 mapas.
- SourceMod e Metamod da imagem base, com os plugins padrão.

Os mapas são oficiais: os jogadores já têm todos, não precisa de FastDL.

## Segurança

O que a imagem faz:

- **Nenhuma senha, token, IP ou admin embutido.** Tudo entra pelas variáveis quando o container liga.
- **Recusa senha de RCON fraca.** A imagem base vem com a senha `123456`; aqui o padrão é vazio e o servidor não liga sem uma senha forte.
- **Recusa valores que injetariam comandos** no `server.cfg` ou na linha de comando do servidor.
- **Só mapas oficiais podem mandar comandos para o console do servidor** (`sv_allow_point_servercommand "official"`).
- **Mapas conferidos** na montagem: vêm da Steam e cada um é verificado como mapa válido.
- **Testes automáticos** antes de cada publicação ([`tests/teste.sh`](tests/teste.sh)): recusa de configurações inseguras, plugins carregados, troca por todos os mapas, nenhum erro registrado, nenhum dado sensível nos arquivos da imagem e desligamento limpo.
- **Varredura de dados sensíveis** no repositório a cada montagem ([`tools/varredura.sh`](tools/varredura.sh)).
- Roda como usuário comum (`tf2`), não como root.

O que recomendamos:

- **Publique só a porta UDP** (`-p 27015:27015/udp`). O RCON usa TCP na mesma porta: sem publicar o TCP, ninguém de fora tenta adivinhar a senha. Para administrar, use `SM_ADMINS` (comandos no jogo) ou `docker exec tf2-zombie ./rcon -H 127.0.0.1 -p 27015 -P "$RCON_PASSWORD" status`.
- Se usar `--network host`, bloqueie o TCP da porta do jogo no firewall.
- Atualize de vez em quando: `docker pull ghcr.io/luci-immerstark/skynet-tf2-zombie:latest` e recrie o container.

Achou um problema de segurança? Não abra issue pública: use **Report a vulnerability**, na aba **Security** deste repositório, que só os mantenedores veem.

## Créditos

- Valve e os autores do Zombie Infection pelos mapas e pelo modo;
- [melkor.tf](https://github.com/melkortf/tf2-servers) pela imagem base (MIT);
- [SteamRE](https://github.com/SteamRE/DepotDownloader) pelo DepotDownloader;
- [AlliedModders](https://www.sourcemod.net/) pelo SourceMod e Metamod:Source.

## Licença

GPLv3 (veja [LICENSE](LICENSE)). Dentro da imagem, a licença fica em `/home/tf2/server/LICENSES`.

---

## English

A ready-to-run **TF2 Zombie Infection** server image: the 6 official `zi_` maps (downloaded straight from Steam at build time, since the base image does not ship them), map rotation and mode settings, built on melkor.tf's [`tf2-sourcemod`](https://github.com/melkortf/tf2-servers) image.

```bash
docker run -d --name tf2-zombie --restart unless-stopped \
  --env-file zombie.env -p 27015:27015/udp \
  ghcr.io/luci-immerstark/skynet-tf2-zombie:latest
```

- `RCON_PASSWORD` is **required** (at least 12 characters: letters, digits and `. _ - @ % + =`). The server refuses to start without it or with a weak one (the base image defaults to `123456`).
- Other variables: `SERVER_HOSTNAME`, `SERVER_PASSWORD`, `SERVER_TOKEN` (GSLT), `SM_ADMINS` (comma-separated SteamIDs, full access), `SERVER_TAGS`, `SERVER_REGION`, `PORT`, `TICKRATE`.
- No passwords, tokens, IPs or admins are baked in, only official maps may run server commands, and every release passes automated tests.
- Publish only the UDP port; RCON uses TCP on the same port, so leaving TCP closed keeps it off the internet.
- Licensed under GPLv3.
