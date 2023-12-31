#!/bin/sh
#author: fawaz.tahir
#desc: Sets up the Lark dependency of a module.

if [ $# -ne 2 ]; then
    echo $0: usage: Specify name of module, eg. MailSDK, followed by directory of local, ready-to-build Lark iOS client repo.
    exit 1
fi

if ! [ -d $1 ]; then
    echo $0: Error: Directory $1 does not exist.
    exit 1
fi

if ! [ -d $2 ]; then
    echo $0: Error: Directory $2 does not exist.
    exit 1
fi

# Install necessary tools.
if ! [ -x "$(command -v brew)" ]; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

if ! [ -x "$(command -v git)" ]; then
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	brew doctor
	brew install git
fi

if ! [ -x "$(command -v bundle)" ]; then
	brew install bundler
fi

if ! [ -x "$(command -v fastlane)" ]; then
	gem install fastlane -NV
fi

# Merge latest master into possibly outdated branch.
git pull origin master
git merge --no-commit origin/master
git commit -m "Merged master into branch"

# Copy the Lark iOS client repo and pull latest.
tmpFolder="tmp"
tmpLarkRepo="tmp/ios-client"
rm -rf $tmpFolder
mkdir -p $tmpFolder
cp -a $2 $tmpFolder
cd $tmpLarkRepo
git clean -f
git checkout .
git pull
git checkout feature/mail/develop
git pull

# Set the module location to the one we are testing.
sed -i .old "s#pod '$1', '.*#pod '$1', :path => '../../$1', :inhibit_warnings => false#g" Podfile

# [Temporary] Update Fastfile to include the new unit test lane.
rm fastlane/Fastfile
echo '# coding: utf-8
fastlane_version "2.108.0"
default_platform :ios

platform :ios do
  desc "Runs unit tests for a specific module."
  lane :unittests do |options|

    # ENV['FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT'] ||= '60'

    # # Enable `SWIFT_WHOLE_MODULE_OPTIMIZATION`, see 'Podfile' for more detail.
    # ENV['SWIFT_WHOLE_MODULE_OPTIMIZATION'] = 'YES'

    begin
      sh "cd .. && rm -rf Pods/LarkAppResources*"
      sh "pod install --clean-install"
    rescue
      puts "Executing Pod Repo Update!"
      sh "pod install --clean-install --repo-update"
    end
    scan(scheme: "LarkTests", fail_build: true)
  end
end' >> fastlane/Fastfile

# Restore working directory to the original directory.
cd ../../
