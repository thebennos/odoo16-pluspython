FROM docker.io/bitnami/odoo:16

RUN pip install pika cython numpy pendulum boto3 url-parser pandas dropbox xw_utils>=1.0.13
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3-numpy \
    python3-boto3 \
    python3-dropbox \
    python3-crontab \
    python3-pandas 
