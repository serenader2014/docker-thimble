DB_URL=${THIMBLE_DB_USER}:${THIMBLE_DB_PASSWORD}@${THIMBLE_DB_HOST}:${THIMBLE_DB_PASSWORD}

sed -i -e "s/postgres\:\/\/\/publish/postgresql:\/\/$DB_URL\/$THIMBLE_DB_PUBLISH/g" /var/thimble/publish.webmaker.org/.env
sed -i -e "s/example.org\/oauth_redirect/localhost:3500\/callback/g" /var/thimble/id.webmaker.org/scripts/test-data.sql
cd /var/thimble/publish.webmaker.org/ && npm run knex
su - postgres -c "psql postgresql://$DB_URL/$THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/create-tables.sql"
su - postgres -c "psql postgresql://$DB_URL/$THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/test-data.sql"
