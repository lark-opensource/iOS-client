#!/bin/sh

bundle install

bundle exec lark-project update_self 

bundle exec lark-project synclock .

bundle exec pod install