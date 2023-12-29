#!/data/data/com.termux/files/usr/bin/bash

set -e

domain_name="$1"
staging="$2"
size="$(stty -a </dev/pts/0 | grep -Po '(?<=columns )\d+')"

lines(){
	eval "printf -- '-%.0s' {1..$size}"
}

# Check for arguments
if [ -z "$domain_name" ]; then
	echo "specify your domain name: "
	read -r domain_name <&1
	if test -z "$domain_name" ; then 
		echo "No domain name specified"
		exit
	fi
	if test -z "$staging" ; then
		echo "would you like to use certbot's staging environment ?"
		echo "https://letsencrypt.org/docs/staging-environment/"
		echo "Use certbot stagin ? N/y: "
		read -r staging <&1
	fi
	if [[ $(echo "$staging" | tr '[:upper:]' '[:lower:]') = y* ]] ; then
		echo "Using staging"
		stage_flag="--test-cert"
	fi
fi

#################### Synapse ####################
#
# Update and dependencies installation.
yes | pkg update -y
pkg innstall -y build-essential binutils python rust libffi sqlite openssl  libjpeg-turbo
pip install virtualenv

# Configuring cargo, see https://github.com/termux/termux-packages/issues/12260
mkdir ~/.cargo
cat << EOF > ~/.cargo/config.toml
[profile.dev]
lto = false
[profile.release]
lto = false
[profile.test]
lto  =false
[profile.bench]
lto = false
EOF

# Required for rust to build python cryptography package
CARGO_BUILD_TARGET="$(rustc --print target-list | grep android | grep "$(uname -m | cut -d7 -f1)" )"
export CARGO_BUILD_TARGET

# Creating synapse directory and initializing it with a virtenv
mkdir -p "$PREFIX/opt/synapse"
virtualenv -p python3 "$PREFIX/opt/synapse/env"

# Installing what's needed (included in official docs
pip="$PREFIX/opt/synapse/env/bin/pip"
$pip install --upgrade pip
$pip install --upgrade setuptools
$pip install matrix-synapse

# Configuring synapse
cd "$PREFIX/opt/synapse"
./env/bin/python -m synapse.app.homeserver \
	--server-name "$domain_name" \
	--config-path homeserver.yaml \
	--generate-config \
	--report-stats=no


echo 'suppress_key_server_warning: true' >> homeserver.yaml
echo 'serve_server_wellknown: true' >> homeserver.yaml

# Setting up synctl
cat << EOF > "$PREFIX/bin/synctl"
#!$PREFIX/bin/bash

cd \$PREFIX/opt/synapse
source ./env/bin/activate
./env/bin/synctl "\$@"
EOF

chmod +x "$PREFIX/bin/synctl"


################# nginx-certbot #################
################# *Installation  #################
pkg install -y nginx termux-services
python -m venv "$PREFIX/opt/certbot"
pip="$PREFIX/opt/certbot/bin/pip"
$pip install --upgrade pip
$pip install certbot certbot-nginx
if ! test -f "$PREFIX/bin/certbot" ; then
	ln -s "$PREFIX/opt/certbot/bin/certbot" "$PREFIX/bin/certbot"
fi
cp "$PREFIX/etc/nginx/nginx.conf" "$PREFIX/etc/nginx/nginx.conf.orig"
curl "https://raw.githubusercontent.com/medanisjbara/synapse-termux/main/nginx.conf" > "$PREFIX/etc/nginx/nginx.conf"
mkdir -p "$PREFIX/etc/nginx/sites-available" "$PREFIX/etc/nginx/sites-enabled"

cat << EOF > "$PREFIX/etc/nginx/sites-available/matrix"
server {
        server_name $domain_name;

        location / {
                proxy_pass http://localhost:8008;
        }

	location ~* ^(\/_matrix|\/_synapse\/client) {
                proxy_pass http://localhost:8008;
                proxy_set_header X-Forwarded-For \$remote_addr;
                client_max_body_size 50M ;
        }

}
EOF

if ! test -L "$PREFIX/etc/nginx/sites-enabled/matrix" ; then
	ln -s "$PREFIX/etc/nginx/sites-available/matrix" "$PREFIX/etc/nginx/sites-enabled"
fi
lines
echo "Running nginx test"

if nginx -t ; then
	echo "Test passed"
else
	lines
	echo "Test didn't pass, please solve this error and/report the issue to https://github.com/medanisjbara/synapse-termux"
	exit
fi

# Sourcing services daemon
# shellcheck source=/dev/null
source "$PREFIX/etc/profile.d/start-services.sh"

sv up nginx

lines
echo "Preparations have been made correctly. To be able to get the ssl_certificate please forward the port 8080 on LAN to port 80 on WAN, And While you're at it, consider forwarding port 8443 on LAN to port 443 on WAN since you will need it later."
echo "You can find this in your router settings"
echo -n "After doing so, press enter to continue."
read -r <&1
lines
certbot --work-dir "$PREFIX"/var/lib/letsencrypt --logs-dir "$PREFIX"/var/log/letsencrypt --config-dir "$PREFIX"/etc/letsencrypt --nginx-server-root "$PREFIX"/etc/nginx --http-01-port 8080 --https-port 8443 "$stage_flag" -v --nginx -d "$domain_name" <&1

if ! grep -q ssl_certificate "$PREFIX/etc/nginx/sites-available/matrix" ; then
	echo "Seems like certbot worked but didn't change your config file. Please visit the following link"
	echo "https://github.com/medanisjbara/synapse-termux/blob/main/GUIDE.md#certbot-didnt-setup-the-config"
fi

sed 's/ 80;/ 8080;/g' "$PREFIX/etc/nginx/sites-available/matrix" -i
sed 's/ 443;/ 8443;/g' "$PREFIX/etc/nginx/sites-available/matrix" -i

synctl start

echo
echo "Installation completed without errors. Your matrix server is running."
echo "Happy Chatting !!"
