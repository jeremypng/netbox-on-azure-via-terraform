apt-get update -q=2
apt-get upgrade -q=2
apt-get autoremove -q=2
apt-get -q=2 install postgresql libpq-dev 
systemctl start postgresql
systemctl enable postgresql
PGSQL_PASS=`date +%s | sha256sum | base64 | head -c 32 ; echo`
echo "export PGSQL_PASS=$PGSQL_PASS" >> .bashrc
echo '\x \\ CREATE DATABASE netbox; \\ CREATE USER netbox WITH PASSWORD '$PGSQL_PASS'; \\ GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox; \\ /q' | su -l postgres psql