version: '2'
volumes:
  customer_${account_identifier}_elasticsearch_data:
    external: true
    driver: rancher-nfs
services:
  php:
    image: 575062673063.dkr.ecr.eu-central-1.amazonaws.com/warehouseplus/api:1.18.8
    environment:
      SYMFONY_ENV: prod
      SYMFONY__VERSION_TAG: 1.18.8
      SYMFONY__DATABASE_HOST: database
      SYMFONY__DATABASE_NAME: customer_${account_identifier}
      SYMFONY__DATABASE_USER: customer_${account_identifier}
      SYMFONY__DATABASE_PASSWORD: ${database_password}
      SYMFONY__MAILER_HOST: email-smtp.eu-central-1.amazonaws.com
      SYMFONY__MAILER_USER: ${mailer_access_key}
      SYMFONY__MAILER_PASSWORD: ${mailer_secret_key}
      SYMFONY__AWS_S3_BUCKET: warehouseplus
      SYMFONY__AWS_S3_REGION: eu-central-1
      SYMFONY__AWS_S3_DIRECTORY: ${account_identifier}
      SYMFONY__AWS_ACCESS_KEY: ${bucket_access_key}
      SYMFONY__AWS_SECRET_KEY: ${bucket_secret_key}
      SYMFONY__HOST_ADMIN_PANEL: https://${account_identifier}.warehouseplus.de
      SYMFONY__RABBITMQ_HOST: queue
      SYMFONY__RABBITMQ_PORT: 5672
      SYMFONY__RABBITMQ_USER: ${rabbitmq_user}
      SYMFONY__RABBITMQ_PASS: ${rabbitmq_pass}
      SYMFONY__RABBITMQ_VHOST: /
    stdin_open: true
    external_links:
    - mysql/mysql:database
    - rabbitmq/rabbitmq:queue
    tty: true
    labels:
      io.rancher.container.pull_image: always
{{ .Values.api_labels | indent 6 }}
  consumer:
    image: 575062673063.dkr.ecr.eu-central-1.amazonaws.com/warehouseplus/api:1.18.8
    command: consume
    environment:
      SYMFONY_ENV: prod
      SYMFONY__VERSION_TAG: 1.18.8
      SYMFONY__DATABASE_HOST: database
      SYMFONY__DATABASE_NAME: customer_${account_identifier}
      SYMFONY__DATABASE_USER: customer_${account_identifier}
      SYMFONY__DATABASE_PASSWORD: ${database_password}
      SYMFONY__MAILER_HOST: email-smtp.eu-central-1.amazonaws.com
      SYMFONY__MAILER_USER: ${mailer_access_key}
      SYMFONY__MAILER_PASSWORD: ${mailer_secret_key}
      SYMFONY__AWS_S3_BUCKET: warehouseplus
      SYMFONY__AWS_S3_REGION: eu-central-1
      SYMFONY__AWS_S3_DIRECTORY: ${account_identifier}
      SYMFONY__AWS_ACCESS_KEY: ${bucket_access_key}
      SYMFONY__AWS_SECRET_KEY: ${bucket_secret_key}
      SYMFONY__HOST_ADMIN_PANEL: https://${account_identifier}.warehouseplus.de
      SYMFONY__RABBITMQ_HOST: queue
      SYMFONY__RABBITMQ_PORT: 5672
      SYMFONY__RABBITMQ_USER: ${rabbitmq_user}
      SYMFONY__RABBITMQ_PASS: ${rabbitmq_pass}
      SYMFONY__RABBITMQ_VHOST: /
    stdin_open: true
    external_links:
    - mysql/mysql:database
    - rabbitmq/rabbitmq:queue
    volumes:
    - /app
    tty: true
    labels:
      io.rancher.container.pull_image: always
  api:
    image: webplates/symfony-nginx
    environment:
      FPM_HOST: php
      FPM_PORT: '9000'
      UPLOAD_MAX_SIZE: 100m
    stdin_open: true
    external_links:
    - mysql/mysql:database
    - rabbitmq/rabbitmq:queue
    tty: true
    volumes_from:
    - php
    labels:
      io.rancher.container.pull_image: always
      io.rancher.sidekicks: php
  portal:
    image: 575062673063.dkr.ecr.eu-central-1.amazonaws.com/warehouseplus/admin:1.18.1
    environment:
      REACT_APP_VERSION: 1.18.1
      REACT_APP_API_CLIENT_ID: 1_15e7tdk08wao8gsw4g8ssoc04skc0o4c44gw04w4sk488888og
      REACT_APP_API_CLIENT_SECRET: 3yygqjselgg0s8ggok8ks0s4o8cg80oss4sskkc8sc0wksc04g
      REACT_APP_API_URL: https://api.${account_identifier}.warehouseplus.de
    stdin_open: true
    tty: true
    labels:
      io.rancher.container.pull_image: always
  letsencrypt:
    image: vxcontrol/rancher-letsencrypt:v1.0.0
    environment:
      API_VERSION: Production
      CERT_NAME: customer-${account_identifier}
      DNS_RESOLVERS: 8.8.8.8:53,8.8.4.4:53
      {{- if eq .Values.additional_domains "" }}
      DOMAINS: ${account_identifier}.warehouseplus.de,api.${account_identifier}.warehouseplus.de
      {{- else }}
      DOMAINS: ${account_identifier}.warehouseplus.de,api.${account_identifier}.warehouseplus.de,${additional_domains}
      {{- end }}
      EMAIL: webmaster@warehouseplus.de
      EULA: 'Yes'
      PROVIDER: HTTP
      PUBLIC_KEY_TYPE: RSA-2048
      RENEWAL_PERIOD_DAYS: '30'
      RENEWAL_TIME: '2'
      RUN_ONCE: 'false'
    volumes:
    - /var/lib/rancher:/var/lib/rancher
    labels:
      io.rancher.container.agent.role: environment
      io.rancher.container.create_agent: 'true'
  elasticsearch:
    image: elasticsearch:6.8.23
    mem_limit: 2147483648
    environment:
      - xpack.security.enabled=false
      - discovery.type=single-node
      - TAKE_FILE_OWNERSHIP="true"
    volumes:
      - customer_${account_identifier}_elasticsearch_data:/usr/share/elasticsearch/data
