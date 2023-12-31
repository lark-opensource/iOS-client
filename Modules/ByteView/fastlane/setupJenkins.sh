#!/bin/sh
echo "setup swiftlint"
brew ls --versions swiftlint > /dev/null || brew install swiftlint
echo "setup sonar-scanner"
brew ls --versions sonar-scanner > /dev/null || brew install sonar-scanner
echo "setup bundle"
bundle config --local build.nokogiri --use-system-libraries --with-xml2-include=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/libxml2/
export GEM_HOME=~/.gem; bundle install
echo "setup lizard"
type ~/Library/Python/2.7/bin/lizard > /dev/null || pip install lizard --user
