FROM debian:buster-slim as base
ARG TARGETARCH
WORKDIR /tmp

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
COPY ./checksums.txt .
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates=20200601~deb10u2 \
    curl \
    dirmngr \
    fontconfig \
    fonts-noto-cjk \
    gnupg \
    libssl-dev \
    libx11-6 \
    libxext6 \
    libxrender1 \
    node-less \
    npm=5.8.0+ds6-4+deb10u \
    python3-num2words \
    python3-pdfminer \
    python3-pip \
    python3-phonenumbers=8.9.10-1 \
    python3-pyldap \
    python3-qrcode \
    python3-renderpm \
    python3-setuptools \
    python3-slugify \
    python3-vobject \
    python3-watchdog \
    python3-xlrd \
    python3-xlwt \
    python3-numpy \
    python3-boto3 \
    python3-dropbox \
    python3-crontab \    
    python3-pandas \
    wget \
    xfonts-75dpi \
    xfonts-base \
    xz-utils && \
 apt-get clean && \
 rm -rf /var/lib/apt/lists/*

FROM base as base_amd64
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** download wkhtmltox package ****" && \
  wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb && \
  sha1sum ./wkhtmltox_0.12.6-1.buster_amd64.deb | sha1sum -c ./checksums.txt --ignore-missing || if [[ "$?" -eq "141" ]]; then true; else exit $?; fi && \
  mv ./wkhtmltox_0.12.6-1.buster_amd64.deb ./wkhtmltox.deb

FROM base as base_arm64
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** download wkhtmltox package ****" && \
  wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_arm64.deb && \
  sha1sum ./wkhtmltox_0.12.6-1.buster_arm64.deb | sha1sum -c ./checksums.txt --ignore-missing || if [[ $? -eq 141 ]]; then true; else exit $?; fi && \
  mv ./wkhtmltox_0.12.6-1.buster_arm64.deb ./wkhtmltox.deb

FROM base as base_arm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** download wkhtmltox package ****" && \
  wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.raspberrypi.buster_armhf.deb && \
  sha1sum ./wkhtmltox_0.12.6-1.raspberrypi.buster_armhf.deb | sha1sum -c ./checksums.txt --ignore-missing || if [[ $? -eq 141 ]]; then true; else exit $?; fi && \
  mv ./wkhtmltox_0.12.6-1.raspberrypi.buster_armhf.deb ./wkhtmltox.deb

# hadolint ignore=DL3008
FROM base_${TARGETARCH}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  # Avoid the pesky 141 exit code
  echo "**** install wkhtmltox ****" && \
  apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
  rm -rf /var/lib/apt/lists/* ./wkhtmltox.deb && \
  echo "**** install latest postgresql-client ****" && \
  echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list && \
  GNUPGHOME="$(mktemp -d)" && \
  export GNUPGHOME && \
  repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' && \
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" && \
  gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc && \
  gpgconf --kill all && \
  rm -rf "$GNUPGHOME" && \
  apt-get update && \
  apt-get install --no-install-recommends -y postgresql-client=11+200+deb10u4 && \
  rm -f /etc/apt/sources.list.d/pgdg.list && \
  rm -rf /var/lib/apt/lists/* && \
  echo "**** Install rtlcss (on Debian buster) ****" && \
  npm config set strict-ssl false && \
  npm install -g rtlcss

# Install Odoo
ARG VERSION
ARG RELEASE
ARG CHECKSUM
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** install odoo ****" && \
  curl -o odoo.deb -sSL http://nightly.odoo.com/${VERSION}/nightly/deb/odoo_${VERSION}.${RELEASE}_all.deb && \
  echo "${CHECKSUM}  odoo.deb" | sha256sum -c && \
  apt-get update && \
  apt-get -y install --no-install-recommends ./odoo.deb && \
  rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
WORKDIR /
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN \
  echo "**** Set permissions ****" && \
  chown odoo /etc/odoo/odoo.conf && \
  mkdir -p /mnt/extra-addons && \
  chown -R odoo /mnt/extra-addons && \
  chmod a+x /entrypoint.sh && \
  chmod a+x /usr/local/bin/wait-for-psql.py
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
