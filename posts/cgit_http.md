---
Title: Setting up Cgit With Smart-HTTP
Author: Shinji
Date: 2021-12-31
Summary: While cgit only supports "dumb" http transport, I set it up to support smart http with git's http backend.
Draft: false
Tags: [linux, software]
---

I followed [Luke's guide](https://landchad.net/cgit) to set up cgit on my server, but it didn't seem to support HTTP clone at all. The HTTP clone only worked when I set the value of the `GIT_SMART_HTTP` environment variable to `0`, and as the [documentation](https://git.zx2c4.com/cgit/tree/cgitrc.5.txt) suggests, cgit doesn't support smart HTTP transport, so if I needed my git server to support smart HTTP, I'd have to serve the repository using other software like `git`'s HTTP backend.

## The Nginx Config (on Debian)
After setting up cgit, your nginx configuration should look like this:
```nginx
server {
    server_name git.example.org;

    root /usr/share/cgit ;
    try_files $uri @cgit ;

    location @cgit {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /usr/lib/cgit/cgit.cgi;
        fastcgi_param PATH_INFO $request_uri;
        fastcgi_param QUERY_STRING $query_string;
        fastcgi_pass unix:/run/fcgiwrap.socket;
    }
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/git.example.org/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/git.example.org/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

}
```

Suppose you have `git` installed, you only have to [route the `git` traffic to the HTTP backend cgi](https://stackoverflow.com/questions/6414227/how-to-serve-git-through-http-via-nginx-with-user-password), like below:
```
server {
	server_name git.example.org;
	root /usr/share/cgit;
	try_files $uri @cgit;
	location ~ ^.*/objects/([0-9a-f]+/[0-9a-f]+|pack/pack-[0-9a-f]+.(pack|idx))$ {
		root /home/git/;
	}

	location ~ ^.*/(HEAD|info/refs|objects/info/.*|git-(upload|receive)-pack)$ {
		root /home/git/;

		fastcgi_pass  unix:/var/run/fcgiwrap.socket;
		fastcgi_param SCRIPT_FILENAME   /usr/lib/git-core/git-http-backend;
		fastcgi_param PATH_INFO         $uri;
		fastcgi_param GIT_PROJECT_ROOT  /srv/git;
		fastcgi_param GIT_HTTP_EXPORT_ALL "";
		fastcgi_param REMOTE_USER $remote_user;
		include fastcgi_params;
	}
	location @cgit {
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME /usr/lib/cgit/cgit.cgi;
		fastcgi_param PATH_INFO $request_uri;
		fastcgi_param QUERY_STRING $query_string;

		fastcgi_param HTTP_HOST $server_name;
		fastcgi_pass unix:/run/fcgiwrap.socket;
	}
	listen 443 ssl;
	ssl_certificate /etc/letsencrypt/live/git.example.org/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/git.example.org/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

}
```

Now reload the nginx server. Smart HTTP clone should be working now =3
