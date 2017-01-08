if [[ -z "$BRAMBLE_HOST" || -z "$THIMBLE_HOST" || -z "$ID_HOST" || -z "$LOGIN_HOST" || -z "$PUBLISHED_HOST" ]]; then
    echo host env is not complete.
    exit
fi;
service postgresql start

DB_URL=${THIMBLE_DB_USER}:${THIMBLE_DB_PASSWORD}@${THIMBLE_DB_HOST}:${THIMBLE_DB_PORT}
TEST_DATA="INSERT INTO clients VALUES
    ( 'test',
      'test',
      '[\"password\", \"authorization_code\"]'::jsonb,
      '[\"code\", \"token\"]'::jsonb,
      'http://$THIMBLE_HOST/callback' )"

sed -i -e "s/export NODE_ENV=\"development\"/export NODE_ENV=\"production\"/g" /var/thimble/thimble.mozilla.org/.env
sed -i -e "s/export APP_HOSTNAME=\"http:\/\/localhost:3500\"/export APP_HOSTNAME=\"http:\/\/$THIMBLE_HOST\"/g" /var/thimble/thimble.mozilla.org/.env
sed -i -e "s/export BRAMBLE_URI=\"http:\/\/localhost:8000\"/export BRAMBLE_URI=\"http:\/\/$BRAMBLE_HOST\"/g" /var/thimble/thimble.mozilla.org/.env
sed -i -e "s/export PUBLISH_HOSTNAME=\"http:\/\/localhost:2015\"/export PUBLISH_HOSTNAME=\"http:\/\/$PUBLISH_HOSTNAME\"/g" /var/thimble/thimble.mozilla.org/.env
sed -i -e "s/http:\/\/localhost:8001/http:\/\/$PUBLISHED_HOST/g" /var/thimble/thimble.mozilla.org/.env
sed -i -e "s/export OAUTH_AUTHORIZATION_URL=\"http:\/\/localhost:1234\"/export OAUTH_AUTHORIZATION_URL=\"http:\/\/$ID_HOST\"/g" /var/thimble/thimble.mozilla.org/.env

sed -i -e "s/export HOST=localhost/export HOST=$ID_HOST/g" /var/thimble/id.webmaker.org/.env
sed -i -e "s/export POSTGRE_CONNECTION_STRING=postgre:\/\/localhost:5432\/webmaker_oauth_test/export POSTGRE_CONNECTION_STRING=postgre:\/\/$DB_URL\/$THIMBLE_DB_OAUTH/g" /var/thimble/id.webmaker.org/.env
sed -i -e "s/export URI=http:\/\/localhost:1234/export URI=http:\/\/$ID_HOST/g" /var/thimble/id.webmaker.org/.env

sed -i -e "s/export APP_HOSTNAME=\"http:\/\/localhost:3000\"/export APP_HOSTNAME=\"http:\/\/$LOGIN_HOST\"/g" /var/thimble/login.webmaker.org/.env

sed -i -e "s/export DATABASE_URL=postgres:\/\/\/publish/export DATABASE_URL=postgres:\/\/thimble:password@127.0.0.1:5432\/publish/g" /var/thimble/publish.webmaker.org/.env
sed -i -e "s/export PUBLIC_PROJECT_ENDPOINT=\"localhost:8001\"/export PUBLIC_PROJECT_ENDPOINT=\"$PUBLISHED_HOST\"/g" /var/thimble/publish.webmaker.org/.env

sed -i -e "s/THIMBLE_HOST/$THIMBLE_HOST/g" /etc/nginx/sites-enabled/default
sed -i -e "s/BRAMBLE_HOST/$BRAMBLE_HOST/g" /etc/nginx/sites-enabled/default
sed -i -e "s/ID_HOST/$ID_HOST/g" /etc/nginx/sites-enabled/default
sed -i -e "s/LOGIN_HOST/$LOGIN_HOST/g" /etc/nginx/sites-enabled/default
sed -i -e "s/PUBLISHED_HOST/$PUBLISHED_HOST/g" /etc/nginx/sites-enabled/default

cat "$TEST_DATA" > /var/thimble/id.webmaker.org/scripts/test-data.sql
cd /var/thimble/publish.webmaker.org/ && npm run knex
su - postgres -c "psql postgresql://$DB_URL/$THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/create-tables.sql"
su - postgres -c "psql postgresql://$DB_URL/$THIMBLE_DB_OAUTH -f /var/thimble/id.webmaker.org/scripts/test-data.sql"

cd /var/thimble/brackets && npm start &
cd /var/thimble/publish.webmaker.org && npm start &
cd /var/thimble/id.webmaker.org && npm start &
cd /var/thimble/login.webmaker.org && npm start &
cd /var/thimble/thimble.mozilla.org && npm start &
service nginx start
