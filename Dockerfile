FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

	##### Dependências #####

RUN apt update && apt install gnupg2 wget curl -y

ADD conf/apt-requirements /opt/sources/

RUN echo "deb http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
RUN apt update && apt install postgresql-client-16 -y

WORKDIR /opt/sources/
RUN apt-get install -y --no-install-recommends $(grep -v '^#' apt-requirements)

RUN apt-get clean && apt-get update && apt-get install -y locales

RUN locale-gen en_US en_US.UTF-8 pt_BR pt_BR.UTF-8 && \
    dpkg-reconfigure locales

ENV LC_ALL pt_BR.UTF-8

RUN pip3 install setuptools && pip3 install --no-cache-dir --upgrade pip

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
RUN dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb

ADD https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb /opt/sources/wkhtmltox.deb
RUN dpkg -i wkhtmltox.deb && rm wkhtmltox.deb

RUN mkdir /opt/odoo/
WORKDIR /opt/odoo/
RUN mkdir private

##### Configurações Odoo #####

ADD conf/supervisord.conf /etc/supervisor/supervisord.conf

RUN mkdir /var/log/odoo && \
    mkdir /opt/dados && \
    mkdir /var/log/supervisord && \
    touch /var/log/odoo/odoo.log && \
    touch /var/run/odoo.pid && \
    ln -s /opt/odoo/odoo/odoo-bin /usr/bin/odoo-server && \
    ln -s /etc/odoo/odoo.conf && \
    ln -s /var/log/odoo/odoo.log && \
    useradd --system --home /opt --shell /bin/bash --uid 1040 odoo && \
    chown -R odoo:odoo /opt && \
    chown -R odoo:odoo /var/log/odoo && \
    chown odoo:odoo /var/run/odoo.pid

##### Finalização do Container #####

WORKDIR /opt/odoo
