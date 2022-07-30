#!/data/data/com.termux/files/usr/bin/bash

set -e


augeas_version="1.12.0"
domain_name="$1"

# Check for arguments
if [ -z "$domain_name" ]; then
	echo "specify your dimain as an argument to the script."
	exit 1
fi

#################### Synapse ####################
#
# Update and dependencies installation.
yes | pkg update -y
pkg innstall -y build-essential binutils python rust libffi sqlite openssl  libjpeg-turbo
pip install virtualenv

# Required for rust to build python cryptography package
CARGO_BUILD_TARGET="$(rustc --print target-list | grep android | grep "$(uname -m | cut -d7 -f1)" )"
export CARGO_BUILD_TARGET

# Creating synapse directory and initializing it with a virtenv
mkdir -p $PREFIX/opt/synapse
virtualenv -p python3 $PREFIX/opt/synapse/env

# Installing what's needed (included in official docs
pip=$PREFIX/opt/synapse/env/bin/pip
$pip install --upgrade pip
$pip install --upgrade setuptools
$pip install matrix-synapse

# Configuring synapse
cd $PREFIX/opt/synapse
./env/bin/python -m synapse.app.homeserver \
	--server-name "$domain_name" \
	--config-path homeserver.yaml \
	--generate-config \
	--report-stats=no


sed 's/8008/8448/g' homeserver.yaml -i
sed 's/127.0.0.1/0.0.0.0/g' homeserver.yaml -i
echo 'suppress_key_server_warning: true' >> homeserver.yaml
echo 'serve_server_wellknown: true' >> homeserver.yaml

# Setting up synctl
cat << EOF > $PREFIX/bin/synctl
#!$PREFIX/bin/bash

cd \$PREFIX/opt/synapse
source ./env/bin/activate
./env/bin/synctl "\$@"
EOF

chmod +x $PREFIX/bin/synctl

echo "Currently, this is only a matrix-synapse installation. You'll have to rely on guides to setup nginx"
echo "synctl --help for more information on how to use synapse"
echo "Happy Chatting !!"
