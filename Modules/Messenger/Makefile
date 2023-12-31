default:
	git stash; git pull --rebase; git stash pop
	bundle install
	scripts/pod-rp
	bundle exec pod install
	open Lark.xcworkspace

setup:
	command -v bundler > /dev/null || gem install bundler
	bundle install
