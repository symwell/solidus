#!/usr/bin/env bash

# rm tmp/appmap-rspec-all/*

cd api
APPMAP=true bundle exec rspec spec/requests spec/features
cd ..

cd backend
APPMAP=true bundle exec rspec spec/controllers spec/features
cd ..

find tmp/appmap-all -name "*.appmap.json" | grep -E '[^/]{240,}$' | xargs rm
NODE_OPTIONS="--trace-warnings --max-old-space-size=4096"  appmap-js fingerprint tmp/appmap-all

