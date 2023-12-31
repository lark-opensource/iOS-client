#!/bin/bash

conventional-changelog -p angular -i ./CHANGELOG.md -w -r 0 > ./CHANGELOG.md
node ./InternationalScript/ReplaceChangelogLink.js
