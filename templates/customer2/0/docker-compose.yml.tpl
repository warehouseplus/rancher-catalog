version: '2'
services:
  php:
    image: 575062673063.dkr.ecr.eu-central-1.amazonaws.com/warehouseplus/open-api:0.0.6
    environment:
      APP_NAME: ${account_identifier}
      APP_ENV: prod
      APP_KEY: "${base64_key}"
      APP_VERSION_TAG: 0.0.6
      APP_URL: https://api.${account_identifier}.warehouseplus.de
      DB_CONNECTION: mysql
      DB_HOST: database
      DB_PORT: 3306
      DB_DATABASE: customer_${account_identifier}
      DB_USERNAME: customer_${account_identifier}
      DB_PASSWORD: ${database_password}
      MAIL_MAILER: log
      MAIL_HOST: email-smtp.eu-central-1.amazonaws.com
      MAIL_PORT: 2525
      MAIL_USERNAME: ${mailer_access_key}
      MAIL_PASSWORD: ${mailer_secret_key}
      MAIL_ENCRYPTION: tls
      MAIL_FROM_ADDRESS: no-reply@warehouseplus.de
      MAIL_FROM_NAME: Warehouse Management
      FILESYSTEM_DISK: s3
      AWS_ACCESS_KEY_ID: ${bucket_access_key}
      AWS_SECRET_ACCESS_KEY: ${bucket_secret_key}
      AWS_DEFAULT_REGION: eu-central-1
      AWS_BUCKET: warehouseplus
      AWS_USE_PATH_STYLE_ENDPOINT: false
      AWS_DIRECTORY: ${account_identifier}
    stdin_open: true
    external_links:
    - mysql/mysql:database
    tty: true
    labels:
      io.rancher.container.pull_image: always
{{ .Values.api_labels | indent 6 }}
  api:
    image: jkaninda/nginx-fpm:alpine
    environment:
      DOCUMENT_ROOT: /var/www/html/public
      PHP_FPM_HOST: 'php:9000'
      UPLOAD_MAX_SIZE: 100m
      CLIENT_MAX_BODY_SIZE: 100M
    stdin_open: true
    external_links:
    - mysql/mysql:database
    tty: true
    volumes_from:
    - php
    labels:
      io.rancher.container.pull_image: always
      io.rancher.sidekicks: php
  portal:
    image: 575062673063.dkr.ecr.eu-central-1.amazonaws.com/warehouseplus/admin:1.21.6
    environment:
      REACT_APP_VERSION: 1.21.6
      REACT_APP_API_CLIENT_ID: 1_15e7tdk08wao8gsw4g8ssoc04skc0o4c44gw04w4sk488888og
      REACT_APP_API_CLIENT_SECRET: 3yygqjselgg0s8ggok8ks0s4o8cg80oss4sskkc8sc0wksc04g
      REACT_APP_API_URL: https://api.${account_identifier}.warehouseplus.de/api/v1.0
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