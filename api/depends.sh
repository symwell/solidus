#!/usr/bin/env bash

set -ex

basedir=~/source/land-of-apps/solidus/api

cd ~/source/appland/appmap-js/packages/cli
exec yarn run appmap depends --base-dir $basedir --appmap-dir $basedir/tmp/appmap
