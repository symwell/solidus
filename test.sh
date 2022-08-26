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

    # from https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
    # allow yaml_unsafe_load else we get the error:
    #
    # $ bin/rails db:seed
    # Running Rails from: /home/test/src/solidus/sandbox
    # Loading seed file: stores
    # Loading seed file: store_credit
    # rails aborted!
    # Psych::DisallowedClass: Tried to load unspecified class: Symbol
    # (eval):2:in `symbol'
    # /home/test/src/solidus/core/db/default/spree/store_credit.rb:11:in `<main>'
    # /home/test/src/solidus/core/db/seeds.rb:16:in `require_relative'
    YAML_CONFIG="\n  config.active_record.use_yaml_unsafe_load = true"
    sed -ie "s:\(.*config.eager_load = false.*\):\1${YAML_CONFIG}:g" sandbox/config/environments/test.rb
    #exit 0

    # At some point this command asks:
    # Would you like to run the migrations now? [Y/n]
#     echo 'Y
# ' | bin/rails railties:install:migrations
    # bin/rails db:migrate
    # the following two currently fail

    # This command asks:
    # Create the admin user (press enter for defaults).
    # Email [admin@example.com]:
    # Password [test123]:
    echo '

' | bin/rails db:seed
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
