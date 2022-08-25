#!/bin/bash

# guarantee solidus containers are not running
docker ps | grep -i solidus
docker stop solidus_dev_pg_1

# start solidus containers
cd solidus_dev
docker-compose up -d pg
docker ps | grep -i solidus

export DATABASE_URL=postgres://postgres@`docker-compose port pg 5432 | xargs echo -n`
echo DATABASE_URL: $DATABASE_URL

cd -

# must also export this else we get:
# DatabaseCleaner::Safeguard::Error::RemoteDatabaseUrl:
#   ENV['DATABASE_URL'] is set to a remote URL. Please refer to https://github.com/DatabaseCleaner/database_cleaner#safeguards
export DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL=true
export DATABASE_CLEANER_ALLOW_PRODUCTION=true # not sure if this must be set too

# verify solidus containers are running
if [ `docker ps | grep solidus_dev_pg_1 | wc -l | xargs echo -n` == "1" ]; then
    echo "Solidus started correctly"
    export DB=postgres
    echo 'Y
' | bin/sandbox
    # At some point this command asks:
    # Would you like to run the migrations now? [Y/n]
#     echo 'Y
# ' | bin/rails railties:install:migrations
    # bin/rails db:migrate
    # the following two currently fail
    # bin/rails db:seed
    # bin/rails spree_sample:load
    bin/build
else
    echo "Solidus didn't start correctly"
fi
