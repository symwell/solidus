#!/bin/bash

# without these "nvm install" doesn't work
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if [ `which chromedriver | wc -l` == "0" ]; then
    echo "You need to install chromedriver"
    exit 1
fi
# When running the tests got stuck once, I saw stuck chromedriver processes
pkill chromedriver

# guarantee solidus containers are not running
docker ps | grep -i solidus
docker stop solidus_dev_pg_1

# start solidus containers
cd solidus_dev
docker-compose up -d pg
docker ps | grep -i solidus

export DATABASE_URL=postgres://postgres@localhost:`docker-compose port pg 5432 | sed -e 's/.*://g' | xargs echo -n`
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
    export RAILS_ENV=test
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
    # bin/build
    echo DATABASE_URL: $DATABASE_URL
    echo To test again run:
    echo "  export RAILS_ENV=test"
    echo "  export DB=postgres"
    echo "  export DATABASE_URL=$DATABASE_URL"
    echo "  export DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL=true"
    echo "  bin/build"
else
    echo "Solidus didn't start correctly"
fi
