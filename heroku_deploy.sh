#!/bin/bash -e

heroku create kv-store --region eu --buildpack "https://github.com/HashNuke/heroku-buildpack-elixir.git"
heroku git:remote --app kv-store

git push heroku master

heroku open --app kv-store
