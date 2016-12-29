: ${THIMBLE_DB_HOST:=postgresql}
: ${THIMBLE_DB_PORT:=5432}
: ${THIMBLE_DB_USER:=${POSTGRESQL_ENV_POSTGRES_USER}}
: ${THIMBLE_DB_PASSWORD:=${POSTGRESQL_ENV_POSTGRES_PASSWORD}}
: ${THIMBLE_DB_PUBLISH:=${POSTGRESQL_ENV_POSTGRES_DB:-public}}
: ${THIMBLE_DB_OAUTH:=webmaker_oauth_test}

if [ -z "$THIMBLE_DB_PASSWORD" ]; then
    THIMBLE_DB_USER=postgres
    service postgresql start
    su - postgres -c "createdb $THIMBLE_DB_PUBLISH"
    su - postgres -c "createdb $THIMBLE_DB_OAUTH"
else
    DB_URL=postgresql://${THIMBLE_DB_USER}:${THIMBLE_DB_PASSWORD}@${THIMBLE_DB_HOST}:${THIMBLE_DB_PASSWORD}/
fi

sed -i -e "s/postgres\:\/\/\/publish/postgresql:\/\/$DB_URL\/$THIMBLE_DB_PUBLISH/g" /var/thimble/publish.webmaker.org/.env
sed -i -e "s/example.org\/oauth_redirect/localhost:3500\/callback/g" /var/thimble/id.webmaker.org/scripts/test-data.sql
cd /var/thimble/publish.webmaker.org/ && npm run knex
if [ -z "$DB_URL" ]; then
    su - postgres -c "psql -d $THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/create-tables.sql"
    su - postgres -c "psql -d $THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/test-data.sql"
else
    su - postgres -c "psql postgresql://$DB_URL/$THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/create-tables.sql"
    su - postgres -c "psql postgresql://$DB_URL/$THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/test-data.sql"
fi
