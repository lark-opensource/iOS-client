#!/bin/bash --login
WORKSPACE=$(pwd)
cd $WORKSPACE/Example
bundle exec fastlane ios demo_package build_number:$BUILD_NUMBER output_directory:$WORKSPACE/archives
