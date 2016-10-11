#!/bin/bash -e

git remote remove heroku
heroku destroy --app kv-store --confirm kv-store
