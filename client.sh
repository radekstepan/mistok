#!/usr/bin/env bash
coffee -c client/mistok.coffee
uglifyjs --overwrite client/mistok.js
cp client/mistok.js server/js