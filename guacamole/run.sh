#!/bin/bash -e

cat <<EOF > ~/.pgpass
${POSTGRES_HOSTNAME:-postgres}:${POSTGRES_PORT:-5432}:${POSTGRES_DATABASE:-postgres}:${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-postgres}
EOF
chmod 600 ~/.pgpass

export PGPASSWORD=${POSTGRES_PASSWORD}
export POSTGRES_DATABASE=${POSTGRS_DATABASE:-guacamole}

if [ ! -f /data/.postgres.initialized ]; then
  createdb -h ${POSTGRES_HOSTNAME:-postgres} -U ${POSTGRES_USER:-postgres} -p ${POSTGRES_PORT:-5432} guacamole
  /opt/guacamole/bin/initdb.sh --postgres | psql -h ${POSTGRES_HOSTNAME:-postgres} -U ${POSTGRES_USER:-postgres} -p ${POSTGRES_PORT:-5432} ${POSTGRES_DATABASE}
  touch /data/.postgres.initialized
fi

mkdir -p /ssl

export GUACD_SSL=false
if [ -f /ssl/acme.json ]; then
  export GUACD_SSL=true
fi

exec /opt/guacamole/bin/start.sh
