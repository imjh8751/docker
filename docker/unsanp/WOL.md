https://github.com/seriousm4x/UpSnap?tab=readme-ov-file

Run the binary

Just download the latest binary from the release page and run it.

Root:

sudo ./upsnap serve --http=0.0.0.0:8090
Non-root:

sudo setcap cap_net_raw=+ep ./upsnap # only once after downloading
./upsnap serve --http=0.0.0.0:8090
For more options check ./upsnap --help or visit PocketBase documentation.

If you want to use network discovery, make sure to have nmap installed and run UpSnap as root/admin.

🐳 Run in docker

You can use the docker-compose example. See the comments in the file for customization.

Non-root docker user:

You will lose the ability to add network devices via the scan page.

Create the mount point first:

mkdir data
Then add user: 1000:1000 to the docker-compose file (or whatever your $UID:$GID is).

Change port

If you want to change the port from 8090 to something else, change the following (5000 in this case):

entrypoint: /bin/sh -c "./upsnap serve --http 0.0.0.0:5000"
healthcheck:
  test: curl -fs "http://localhost:5000/api/health" || exit 1
Install additional packages for shutdown cmd

entrypoint: /bin/sh -c "apk update && apk add --no-cache <YOUR_PACKAGE> && rm -rf /var/cache/apk/* && ./upsnap serve --http 0.0.0.0:8090"
You can search for your needed package here.

Reverse Proxy

Caddy example

upsnap.example.com {
    reverse_proxy localhost:8090
}
Run in sub path

You can run UpSnap on a different path than /, e.g. /upsnap-sub-path/. To do this in caddy, set the following:

http://localhost:8091 {
    handle /upsnap-sub-path/* {
        uri strip_prefix /upsnap-sub-path
        reverse_proxy localhost:8090
    }
}
Or nginx:

http {
    server {
        listen 8091;
        server_name localhost;
        location /upsnap-sub-path/ {
            proxy_pass http://localhost:8090/;
            proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
Paths must end with a trailing /.

