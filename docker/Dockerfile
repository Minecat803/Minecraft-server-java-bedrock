FROM eclipse-temurin:17-jdk

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    jq \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /server/mods /server/config /server/worlds

# Download MohistMC (Forge + Bukkit hybrid)
ARG MC_VERSION=1.20.1
RUN wget -O /server/server.jar \
    "$(curl -s https://mohistmc.com/api/$MC_VERSION | jq -r '.url')"

# Add scripts
COPY deploy-addons.sh /server/
COPY configure-server.sh /server/
RUN chmod +x /server/*.sh

WORKDIR /server
EXPOSE 25565 19132/udp

CMD ["/bin/bash", "-c", "./deploy-addons.sh && ./configure-server.sh && java -Xms2G -Xmx4G -jar server.jar --nogui"]