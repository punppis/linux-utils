FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      coreutils \
      curl \
      gzip \
      openssh-client \
      rsync \
      tar \
      docker.io \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/backup-tool

COPY . .

RUN chmod +x backup-tool setup

ENTRYPOINT ["./backup-tool"]
CMD ["run"]
