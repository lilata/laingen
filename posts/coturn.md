---
Title: A Coturn Configuration Example
Author: Shinji
Date: 2022-03-22
Summary: An example about how to configure coturn properly.
Draft: false
Tags: [software, linux]
---

Maybe you are setting up some remote conference software but it requires WebRTC and doesn't work outside of your local network, and now it's time to introduce some extra software to handle the traffic from NAT. Coturn can come in handy!

## Coturn
Coturn is a TURN server, and you can install it using `apt` on debian(or ubuntu?), very easily:
```
sudo apt install -y coturn
```
### The Configuration File
After the installation, the coturn configuration file will be placed to `/etc/turnserver.conf`, and it's rather long. Fortunately, we do not need to read this file line by line. You can just copy and paste my shitty exmaple of `/etc/turnserver.conf`:
```
syslog
lt-cred-mech
use-auth-secret
no-tls
no-dtls
static-auth-secret=p4ssw0rd
realm=turn.yourdomain.com
external-ip=123.123.123.123
min-port=64000
max-port=65535
```
You should edit the `static-auth-secret`, `realm` and `external-ip` fields to your own information. It is nice to enable `TLS` as well, but I'm lazy and most of the traffic is already encrypted, so I wouldn't worry about safety too much.
### Restart and Enable the Server
I don't know if `apt` will start `coturn` once installed, so I'll just restart it anyway, and enable the service so it can survive a reboot. Execute the following `soystemd` commands to do this:
```
sudo systemctl restart coturn
sudo systemctl enable coturn
```
And you are done! You should be able to configure your live conferencing software accordingly.
#### Additional Info
The default TURN listener port for UDP and TCP is `3478`.

Thanks for reading.
