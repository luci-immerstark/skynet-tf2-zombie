# syntax=docker/dockerfile:1.10
# SKYNET TF2 Zombie Infection: servidor de Zombie Infection pronto, em cima da imagem tf2-sourcemod do melkor.tf.
# O modo vem dentro dos mapas zi_ oficiais da Valve, que a imagem base nao traz: eles sao baixados direto da Steam.
# Nada aqui tem senha, token ou IP: tudo isso entra pelas variaveis de ambiente quando o container liga.

# Imagem base. A montagem automatica (GitHub) troca "latest" pelo digest exato que foi testado.
ARG BASE=ghcr.io/melkortf/tf2-sourcemod/amd64:latest

# ---------- 1. mapas zi_ oficiais, direto da Steam (servidor dedicado do TF2, app 232250, login anonimo) ----------
# DepotDownloader (SteamRE) baixa so os arquivos pedidos, em vez do jogo inteiro. Versao e checksum fixos;
# ele so roda aqui e nao vai para a imagem final.
FROM ubuntu:24.04 AS mapas
ARG DD_VERSION=3.4.0
ARG DD_SHA256=a999dec66b4850fc961bd50366696d23c2d0fad7b18790e6a5647b2f19097a53
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates unzip libssl3t64 \
 && rm -rf /var/lib/apt/lists/*
ADD --checksum=sha256:${DD_SHA256} \
    https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DD_VERSION}/DepotDownloader-linux-x64.zip \
    /tmp/dd.zip
RUN set -eu; \
    unzip -q /tmp/dd.zip -d /opt/dd; chmod 755 /opt/dd/DepotDownloader; \
    printf '%s\n' 'regex:^tf[\\/]maps[\\/]zi_[a-z0-9_]+\.bsp$' > /tmp/lista.txt; \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 /opt/dd/DepotDownloader \
        -app 232250 -os linux -osarch 64 -filelist /tmp/lista.txt -dir /baixado; \
    mkdir -p /mapas; mv /baixado/tf/maps/zi_*.bsp /mapas/; \
    total=$(ls /mapas/zi_*.bsp | wc -l); echo "mapas zi_ baixados: $total"; \
    test "$total" -ge 6; \
    for m in /mapas/*.bsp; do test "$(head -c 4 "$m")" = "VBSP" || { echo "arquivo invalido: $m"; exit 1; }; done; \
    sha256sum /mapas/*.bsp

# ---------- 2. imagem final ----------
FROM ${BASE}
ARG SM=/home/tf2/server/tf/addons/sourcemod

LABEL org.opencontainers.image.title="SKYNET TF2 Zombie Infection" \
      org.opencontainers.image.description="Servidor de TF2 Zombie Infection pronto (mapas zi_ oficiais), sem senhas embutidas" \
      org.opencontainers.image.source="https://github.com/luci-immerstark/skynet-tf2-zombie" \
      org.opencontainers.image.licenses="GPL-3.0-only"

COPY --from=mapas --chown=tf2:tf2 /mapas/ /home/tf2/server/tf/maps/
COPY --chown=tf2:tf2 config/cfg/ /home/tf2/server/tf/cfg/
COPY --chown=tf2:tf2 LICENSE /home/tf2/server/LICENSES/skynet-tf2-zombie-GPL-3.0.txt
COPY --chown=tf2:tf2 --chmod=755 skynet-entrypoint.sh /home/tf2/server/skynet-entrypoint.sh

# Sem valores perigosos de fabrica: a base vem com a senha de RCON 123456 e FastDL de terceiros; aqui ficam vazios
# e o servidor so liga com uma senha forte (veja skynet-entrypoint.sh).
ENV RCON_PASSWORD="" \
    SERVER_HOSTNAME="TF2 Zombie Infection Server" \
    SERVER_PASSWORD="" \
    SERVER_TAGS="zombie,infection,zi" \
    SERVER_REGION="255" \
    DOWNLOAD_URL="" \
    SM_ADMINS=""

USER tf2
ENTRYPOINT ["/home/tf2/server/skynet-entrypoint.sh"]
CMD ["+sv_pure", "1", "+map", "zi_atoll", "+maxplayers", "24"]
