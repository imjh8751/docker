services:
  db:
    image: mariadb:latest
    environment:
      - MYSQL_ALLOW_EMPTY_PASSWORD=yes
      - MYSQL_DATABASE=powerdnsadmin
      - MYSQL_USER=pdns 
      - MYSQL_PASSWORD=mypdns
    ports:
      - 3306:3306 
    restart: always
    volumes:
      - /APP/powerdns/pda-mysql:/var/lib/mysql
  pdns:
    #build: pdns
    image: pschiffe/pdns-mysql
    hostname: pdns
    domainname: computingforgeeks.com
    restart: always
    depends_on:
      - db
    links:
      - "db:mysql"
    ports:
      - "53:53"
      - "53:53/udp"
      - "8081:8081"
    environment:
      - PDNS_gmysql_host=db
      - PDNS_gmysql_port=3306
      - PDNS_gmysql_user=pdns
      - PDNS_gmysql_dbname=powerdnsadmin
      - PDNS_gmysql_password=mypdns
      - PDNS_master=yes 
      - PDNS_api=yes
      - PDNS_api_key=secret
      - PDNSCONF_API_KEY=secret
      - PDNS_webserver=yes 
      - PDNS_webserver-allow-from=127.0.0.1,10.0.0.0/8,172.0.0.0/8,192.0.0.0/24 
      - PDNS_webserver_address=0.0.0.0 
      - PDNS_webserver_password=Admin2580!
      - PDNS_version_string=anonymous 
      - PDNS_default_ttl=1500 
      - PDNS_allow_notify_from=0.0.0.0 
      - PDNS_allow_axfr_ips=127.0.0.1 

  web_app:
    image: powerdnsadmin/pda-legacy:latest
    container_name: powerdns_admin
    ports:
      - "8080:80"
    depends_on:
      - db
    restart: always
    links:
      - db:mysql
      - pdns:pdns
    logging:
      driver: json-file
      options:
        max-size: 50m
    environment:
      - SQLALCHEMY_DATABASE_URI=mysql://pdns:mypdns@db/powerdnsadmin
      - GUNICORN_TIMEOUT=60
      - GUNICORN_WORKERS=2
      - GUNICORN_LOGLEVEL=DEBUG
