#!/usr/bin/env sh
set -x
cd node-graphql
git pull
cd ..
docker-compose up --build
