FROM debian:buster-slim as base
ARG TARGETARCH
WORKDIR /tmp

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
COPY ./checksums.txt .
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# RUN install_packages  libbrotli1 libbsd0 libbz2-1.0 libc6 libcap2-bin libcom-err2 libcrypt1 libedit2 libffi7 libfreetype6 libgcc-s1 libgmp10 libgnutls30 libgssapi-krb5-2 libhogweed6 libicu67 libidn2-0 libjpeg62-turbo libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.4-2 liblzma5 libmd0 libncursesw6 libnettle8 libnsl2 libp11-kit0 libpng16-16 libpq5 libreadline8 libsasl2-2 libsqlite3-0 libssl1.1 libstdc++6 libtasn1-6 libtinfo6 libtirpc3 libunistring2 libuuid1 libx11-6 libxcb1 libxext6 libxml2 libxrender1 libxslt1.1 procps xfonts-75dpi xfonts-base zlib1g
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    acl \
    curl \
    git \
    ca-certificates \
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
    npm \
    python3-num2words \
    python3-magic \
    python3-pdfminer \
    python3-pip \
    python3-odf \
    python3-phonenumbers \
    python3-pyldap \
    python3-qrcode \
    python3-renderpm \
    python3-setuptools \
    python3-slugify \
    python3-vobject \
    python3-watchdog \
    python3-venv \
    python3-xlrd \
    python3-xlwt \
    python3-numpy \
    python3-boto3 \
    python3-dropbox \
    python3-crontab \    
    python3-pandas \
    wget \
    libxrender1 \
    libpq-dev \
    libffi-dev \
    libjpeg-dev \
    xfonts-75dpi \
    xfonts-base \
    gcc \
    autoconf \ 
    libtool \ 
    pkg-config \ 
    python-opengl  \ 
    python-pil \ 
    python-pyrex \ 
    idle-python2.7  \
    qt4-dev-tools  \
    qt4-designer  \
    libqtgui4  \
    libqtcore4  \
    libqt4-xml \
    libqt4-test \
    libqt4-script \
    libqt4-network \
    libqt4-dbus \
    python-qt4 \
    python-qt4-gl \
    libgle3 \
    python-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libffi-dev \
    libjpeg-dev \
    zlib1g-dev \
    python-dateutil \
    python-docutils \ 
    python-feedparser \ 
    python-jinja2 \
    python-ldap \
    python-libxslt1 \
    python-lxml \
    python-mako \
    python-mock \
    python-openid \
    python-psycopg2 \
    python-psutil \
    python-pychart \
    python-pydot \
    python-pyparsing \
    python-reportlab \
    python-simplejson \
    python-tz python-unittest2 \
    python-vatnumber \
    python-vobject \
    python-webdav \
    python-werkzeug \
    python-xlwt \
    python-yaml \
    python-zsi \
    libxslt1-dev \
    libldap2-dev \
    python3-dev \
    build-essential \
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


# hadolint ignore=DL3008
FROM base_amd64
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
  apt-get install --no-install-recommends -y postgresql-client && \
  rm -f /etc/apt/sources.list.d/pgdg.list && \
  rm -rf /var/lib/apt/lists/* 
RUN echo "**** Install rtlcss (on Debian buster) ****" && \
  npm config set strict-ssl false && \
  npm install -g rtlcss

# Install Odoo
ARG VERSION=16
ARG RELEASE=latest
ARG CHECKSUM
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
#RUN \
#  echo "**** install odoo ****" && \
#  curl -o odoo.deb -sSL https://nightly.odoo.com/16.0/nightly/deb/odoo_16.0.20230722_all.deb && \
#  echo "${CHECKSUM}  odoo.deb" | sha256sum -c && \
#  apt-get update && \
#  apt-get -y install --no-install-recommends ./odoo.deb && \
 # rm -rf /var/lib/apt/lists/* odoo.deb




# Copy entrypoint script and Odoo configuration file
WORKDIR /
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY ./requirements.txt /
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py




RUN adduser --system --group --home=/opt/odoo --shell=/bin/bash odoo 
RUN su - odoo
WORKDIR /opt/odoo
RUN git clone https://github.com/odoo/odoo.git --depth 1 --branch 16.0 --single-branch odoo-server 
RUN chown -R odoo:odoo /opt/odoo/odoo-server
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    gcc \
    libxslt1-dev \
    libldap2-dev \
    python3-dev \
    rustc \
    cython3



RUN cd /opt/odoo/odoo-server
RUN python3 -m venv venv
RUN source venv/bin/activate
RUN pip3 install --upgrade pip
RUN pip3 install wheel
RUN pip3 install --ignore-installed Cython==3.0.0a10 ofxparse==0.21 passlib==1.7.4 Pillow==9.0.1 polib==1.1.0 psutil==5.8.0 psycopg2==2.8.6 pydot==1.4.2 pyopenssl==20.0.1 PyPDF2==1.26.0 pyserial==3.5 python-dateutil==2.8.1 python-ldap==3.4.0 pytz pyusb==1.0.2 reportlab==3.5.59 requests==2.25.1 urllib3==1.26.5 vobject==0.9.6.1 Werkzeug==2.0.2 xlrd==1.2.0 XlsxWriter==1.1.2 xlwt==1.3.* zeep==4.0.0 qrcode==6.1 python-stdnum==1.16 Babel==2.9.1 chardet==4.0.0 cryptography==3.4.8 decorator==4.4.2 docutils==0.16 ebaysdk==2.1.5 freezegun==0.3.15 gevent==21.8.0 greenlet==1.1.2 idna==2.10 Jinja2==2.11.3 libsass==0.20.1 lxml==4.6.5 MarkupSafe==1.1.1 num2words==0.5.9 
# RUN pip3 install -r /opt/odoo/odoo-server/requirements.txt
# RUN source venv/bin/deactivate
RUN exit

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN \
  echo "**** Set permissions ****" && \
  chown odoo /etc/odoo/odoo.conf && \
  mkdir -p /mnt/extra-addons && \
  chown -R odoo /mnt/extra-addons && \
  chmod a+x /entrypoint.sh && \
  chmod a+x /usr/local/bin/wait-for-psql.py

# /etc/systemd/system/odoo.service 
WORKDIR /
COPY ./odoo.service  /etc/systemd/system/odoo.service 

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /opt/odoo/odoo-server/venv/bin/python3 
CMD ["/opt/odoo/odoo-server/odoo-bin"]
