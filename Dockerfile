FROM docker.io/bitnami/odoo:16

RUN pip install pika cython numpy pendulum boto3 url-parser pandas python-crontab dropbox xw_utils>=1.0.13
