# Termux Synapse Guide
This guide will show you how to setup synapse to host your matrix server on termux.
It is just a way of following the official documentations while applying the workarounds that has to be done in termux to survive the harsh Android environment.

## matrix-synapse
### Installation
It is possible to install [Synapse as a Python module](https://matrix-org.github.io/synapse/latest/setup/installation.html#installing-as-a-python-module-from-pypi) from PyPI (which is what were are going to do).  
First install the platform-specific prerequisites.
```shell
$ pkg install build-essential binutils python rust libffi sqlite openssl  libjpeg-turbo
$ pip install virtualenv
```
One of the dependencies of the `matrix-synapse` python module is the [cryptography](https://cryptography.io/en/latest/) which will be built via rust. In most cases, rust will not be able to build it since it cannot determine the build target see [termux-packages#8037](https://github.com/termux/termux-packages/issues/8037).  
The build target can be specified via the `CARGO_BUILD_TARGET` environment variable.  
You can use the command `rustc --print target-list | grep android` to see the target list that you can choose from based on your architecture (ps: You can check your architecture via the command `uname -m`)
Here we will use armv7 architecture as an example.
```shell
$ export CARGO_BUILD_TARGET=armv7-linux-androideabi
```
Now we can carry on with the rest of the official installation instructions. Here we will have the synapse folder under `$PREFIX/opt`
```shell
$ mkdir -p $PREFIX/opt/synapse
$ cd $PREFIX/opt/synapse
$ virtualenv -p python3 env
$ source ./env/bin/activate
$ pip install --upgrade pip
$ pip install --upgrade setuptools
$ pip install matrix-synapse
```

It's now time to generate a configuration file. In the same directory (and while the virtual environment is activated). Execute the following:
```shell

$ cd PATH TO THE PLACE THAT U WANT TO SAVE THE CONFIG
$ python -m synapse.app.homeserver \
    --server-name my.domain.name \
    --config-path homeserver.yaml \
    --generate-config \
    --report-stats=<yes/now>
```
Replace `my.domain.name` with your domain name, and choose whether you'd like to report usage statistics to the developers using the flag `--report-stats=` [read more about this in the official synaps docs](https://matrix-org.github.io/synapse/latest/setup/installation.html#installing-as-a-python-module-from-pypi)

One last step I prefer to add (you can ignore this if you like and use what's provided in the official docs) is to have synctl binary that does what synctl should do in the virtualenv.
Add a file in your `$PREFIX/bin/` (or anywhere in your path) called `synctl` and add the following to it:
```bash
#!/data/data/com.termux/files/usr/bin/bash
 python -m synapse.app.homeserver --config-path=PATH TO THE PLACE THAT U WANT TO SAVE THE CONFIG`
```
Don't forget to make it executable by running the command `chmod +x $PREFIX/bin/synctl`
**NOTE:** It is generally not recommended to add executables to your `$PREFIX/bin`. If you want to do this right, you might want to consider using `$HOME/.local/bin` and adding it to your path.

### Configuration
At this point you can just execute `synctl start` and the server will work (only on your phone) to check it, open a browser and head to `localhost:8008`. On its own, this will not work though. Additional changes have to be made.  

You can open the file `homeserver.yaml` in the synapse directory under `$PREFIX/opt`. The `homeserver.yaml` is very documented and there are a lot of options you can add to it. Here we'll stick to the defaults and change only what's necessary, but feel free to experiment with it.  

As for the needed configuration (what you need to change in order for it to work).

* Add `serve_server_wellknown: true` to the end of the file.

## Nginx And Certbot
### Installation
#### Nginx
Nginx is available via the pkg package manager. You might want to install termux-services to ensure it'll stay running and managed by `runit`
```shell
$ pkg install -y nginx termux-services
```
> and then restart termux so that the service-daemon is started.  

For more read [their wiki](https://wiki.termux.com/wiki/Termux-services).
#### Certbot
cetbot is [available via PyPI](https://certbot.eff.org/instructions?ws=nginx&os=pip), But its support is partial.  
They also mentioned this.  
> If you are on a more obscure or heavily customized system, these instructions may not work and the Certbot team may be unable to help you resolve the problem.

So please if this doesn't work for you, do not bother them with the problem. Instead, post it here, and we might be able to work something out.  

Also, note that this installation ignores the `angueas` dependency for `certbot` as it is not necessary to have in order to obtain the certificate. To read more about this, check the [Installer development](https://eff-certbot.readthedocs.io/en/stable/contributing.html?highlight=augeas#installer-development) section in certbot documentation.  
It is possible to compile augeas on android, but you will need to add `#define __USE_FORTIFY_LEVEL 0` in `gnulib/lib/cdefs.h` to disable FORTIFY since it works differently on android. Check [augeas#760](https://github.com/hercules-team/augeas/issues/760).  

To install certbot, first set up the virtual environment.
```shell
$ python -m venv $PREFIX/opt/certbot
$ $PREFIX/opt/certbot/bin/pip install --upgrade pip
```
Then install certbot in the virtual environment by running this command.
```shell
$ $PREFIX/opt/certbot/bin/pip install certbot certbot-nginx
```
Execute the following instruction on the command line on the machine to ensure that the certbot command can be run.
```shell
$ ln -s $PREFIX/opt/certbot/bin/certbot $PREFIX/bin/certbot
```
And you are done with the installation.
### Configuration
#### nginx
First, the nginx default configuration contains a couple of entries that might interfere with what we need. If you do the rest of the steps using the default configuration. You will most likely bump into a lot of issues such as the fact that the config overwrites the `server_name` causing certbot to misbehave. One can try to run the commands needed to set up everything and fix the problems one at a time. But certbot has a [failed validation limit](https://letsencrypt.org/docs/failed-validation-limit/) of 5 attempts per host name per hour. This means that you can only fail at using this command 5 times per hour.  
You can copy my configs or make your own from scratch if you'd like. My advice is to copy mine first to get your certificate and then make the changes as you no longer have to be afraid if it'll work or not.  

After backing up your default/old configs, Copy the [configuration](/nginx.conf) provided hereto your `$PREFIX/etc/nginx`
```shell
$ cp $PREFIX/etc/nginx/nginx.conf $PREFIX/etc/nginx/nginx.conf.orig
$ curl "https://raw.githubusercontent.com/medanisjbara/synapse-termux/main/nginx.conf" -O $PREFIX/etc/nginx/nginx.conf
```
Next, create the sites-available and sites-enabled directories.
```shell
$ mkdir $PREFIX/etc/nginx/sites-available $PREFIX/etc/nginx/sites-enabled
```
Add the following to `$PREFIX/etc/nginx/sites-available`
```nginx
server {
        server_name your.domain.name;

        location / {
                proxy_pass http://localhost:8008;
        }

	location ~* ^(\/_matrix|\/_synapse\/client) {
                proxy_pass http://localhost:8008;
                proxy_set_header X-Forwarded-For $remote_addr;
                client_max_body_size 50M ;
        }

}
```
**NOTE:** Ofc whenever you change nginx configs. You should test the configuration by executing `nginx -t`. If all goes well, you can continue to the next step. Otherwise, fix the errors that might occur.
AND WE ARE READY TO ENABLE THE NGINX MATRIX SITE.
```shell
$ ln -s $PREFIX/etc/nginx/sites-available/matrix $PREFIX/etc/nginx/sites-enabled
$ sv up nginx
```
Now nginx is running, you can check if it still is using `sv status nginx`. To enable it, use `sv-enable nginx`. Read more about managing services in termux on [their wiki](https://wiki.termux.com/wiki/Termux-services).  
If for whatever reason something didn't work. You can check the log for errors by executing the following command.
```
$ tail -f $PREFIX/var/log/nginx/errors.log
```
If everything went okay until this point. You should check your router and forward your ports to the internet. Here you'll need to forward port 8080 to port 80 , and port 8443 to port 443. You can then execute the certbot command.
#### Certbot
```shell
$ certbot --work-dir $PREFIX/var/lib/letsencrypt --logs-dir $PREFIX/var/log/letsencrypt --config-dir $PREFIX/etc/letsencrypt --nginx-server-root $PREFIX/etc/nginx --http-01-port 8080 --https-port 8443 -v --nginx -d your.domain.name
```
Hopefully, if everything went okay and there are no errors. (I doubt it at this point, but you can open an issue here if you'd like). Then it's time to edit `$PREFIX/ect/nginx/sites-available/matrix` again, just replace 443 with 8443.    
##### Certbot Didn't setup the config.
In some cases `certbot` doesn't add the needed changes to the `$PREFIX/etc/nginx/sites-available/matrix` file. In that case you'll have to edit it manually. If that's the case. Here's how the final file should look like, just remove the old content, and paste this changing `your.domain.name` with your domain name.
```nginx
server {
        server_name your.domain.name;

        location / {
                proxy_pass http://localhost:8008;
        }
        location ~* ^(\/_matrix|\/_synapse\/client) {
                proxy_pass http://localhost:8008;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-For $remote_addr;
                client_max_body_size 50M;
        }

    listen 8443 ssl; # managed by Certbot
    ssl_certificate /data/data/com.termux/files/usr/etc/letsencrypt/live/your.domain.name/fullchain.pem; # managed by Certbot
    ssl_certificate_key /data/data/com.termux/files/usr/etc/letsencrypt/live/your.domain.name/privkey.pem; # managed by Certbot
    include /data/data/com.termux/files/usr/etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /data/data/com.termux/files/usr/etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}
server {
    if ($host = your.domain.name) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


        server_name your.domain.name;
    listen 8080;
    return 404; # managed by Certbot
}
```
And everything should be set by now. Make sure synapse is running by executing `synctl start`.
You can check if your server is running correctly by entering your domain name in [federation tester website](https://federationtester.matrix.org/).

## Finally
This guide is incomplete. Over the next few days. I will continue adding the rest of the steps to have a complete synapse matrix server running on your phone. Until that time, you are somewhat on your own. Consider the guides online (their numbers are huge even though none of them is considering termux) and try to improvise.
