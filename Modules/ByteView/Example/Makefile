PROJECT_FILE = ByteView.xcworkspace
SCHEME = ByteView
PLATFORM = iOS Simulator
DEVICE = iPhone 14 Pro

MODULE = ByteView

CMD = xcodebuild -workspace $(PROJECT_FILE) -scheme $(SCHEME) -destination "platform=$(PLATFORM),name=$(DEVICE)"

install:
	orbit pod install

build:
	$(CMD) build

test:
	$(CMD) -enableCodeCoverage YES test

i18n:
	bundle exec eesc module i18n -n $(MODULE)

open:
	open $(PROJECT_FILE)

close:
	ps -ax | grep 'Xcode$' | awk '{print $1}' | xargs kill -9

install-open: install open

clean:
	$(CMD) clean

clean-pod-cache:
	rm -rf ~/Library/Caches/CocoaPods
	rm -rf ~/.cocoapods
	rm -rf Pods
	rm -f .Podfile.lock .Podfile.strict.lock

clean-derived-data:
	rm -rf `xcodebuild -project ByteView.xcodeproj -showBuildSettings | grep -o "[^=]*/DerivedData" | head -n 1`

clean-all: clean clean-pod-cache clean-derived-data

.PHONY: build test install i18n open clean clean-pod-cache clean-all
default: install open
.DEFAULT_GOAL := install-open