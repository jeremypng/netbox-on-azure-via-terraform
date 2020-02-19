apt-get update -q=2
apt-get upgrade -q=2
apt-get autoremove -q=2
apt-get -q=2 install postgresql libpq-dev 
systemctl start postgresql
systemctl enable postgresql
export PGSQL_PASS=`date +%s | sha256sum | base64 | head -c 32 ; echo`
echo "export PGSQL_PASS=$PGSQL_PASS" >> /var/lib/postgresql/.bashrc
curl https://raw.githubusercontent.com/jeremypng/netbox-on-azure-via-terraform/master/postgres-config.sh | su -l postgres bash