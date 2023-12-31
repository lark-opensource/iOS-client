# http://eescaffold.ee-dns.top/en/
BRANCH = $(shell git symbolic-ref --short -q HEAD)
currentTag = $(shell grep -m 1 s.version ./Bizs/Calendar/Calendar.podspec | cut -d "\"" -f2)
nextTag = $(shell ruby incTag.rb $(currentTag))
larkBranchPath = "origin/develop"
init:
	\curl http://tosv.byted.org/obj/ee-infra-ios/install.sh | bash

update:
	gem update EEScaffold
install:
        pod install
install-update:
	pod install --repo-update
bundle-install-update:
	bundle install; bundle exec pod install --repo-update 

test:
	rm -rf test-report/ 
	EEScaffold --verbose module test -n Calendar --device="platform=iOS Simulator,OS=13.3,name=iPhone 11 Pro" --force

next:
		@echo "当前tag = $(currentTag)"
		@while [ -z "$$CONTINUE" ]; do \
        	read -r -p "确定在 $(BRANCH) 上打 $(nextTag) tag吗? [y/N]: " CONTINUE; \
    	done ; \
    	[ $$CONTINUE = "y" ] || [ $$CONTINUE = "Y" ] || (echo "Exiting."; exit 1;)
		@gsed -i '3c\  s.version = "$(nextTag)"' ./Bizs/Calendar/Calendar.podspec
		@gsed -i '3c\  s.version = "$(nextTag)"' ./Bizs/CalendarFoundation/CalendarFoundation.podspec
		@gsed -i '3c\  s.version = "$(nextTag)"' ./Bizs/CalendarRichTextEditor/CalendarRichTextEditor.podspec
		git add .
		git commit -m "Calendar(Foundation) $(nextTag)"
		git tag $(nextTag)
		@while [ -z "$$PUSH" ]; do \
			read -r -p "需要push到远端吗？[y/N]: " PUSH; \
		done ; \
		if [ $$PUSH = 'y' ] || [ $$PUSH = 'Y' ];then \
			./push.sh; \
		fi

increase_tag:
	EEScaffold module semver increase Calendar
	git commit -m "Calendar $(currentTag)"
	git tag $(currentTag)

tag:
	@if ! hash gsed 2>/dev/null; then \
  	brew install gnu-sed; \
	fi

    ifeq ($(tag),)

		@echo "请输入命令 : make tag tag=(xxx)"
		@echo $(currentTag)
		@echo "当前tag = $(currentTag)"
    else
		@while [ -z "$$CONTINUE" ]; do \
        	read -r -p "确定在 $(BRANCH) 上打 $(tag) tag吗? [y/N]: " CONTINUE; \
    	done ; \
    	[ $$CONTINUE = "y" ] || [ $$CONTINUE = "Y" ] || (echo "Exiting."; exit 1;)
		@gsed -i '3c\  s.version = "$(tag)"' ./Bizs/Calendar/Calendar.podspec
		@gsed -i '3c\  s.version = "$(tag)"' ./Bizs/CalendarFoundation/CalendarFoundation.podspec
		@gsed -i '3c\  s.version = "$(tag)"' ./Bizs/CalendarRichTextEditor/CalendarRichTextEditor.podspec
		git add .
		git commit -m "Calendar $(tag)"
		git tag $(tag)
		@while [ -z "$$PUSH" ]; do \
			read -r -p "需要push到远端吗？[y/N]: " PUSH; \
		done ; \
		if [ $$PUSH = 'y' ] || [ $$PUSH = 'Y' ];then \
			./push.sh; \
		fi
endif

publish:
	EEScaffold module publish -n Calendar -t $(currentTag)
	git push origin $(currentTag)

publish_skip:
	EEScaffold module publish -n Calendar -t $(currentTag) --no-lint-project-git --skip-build
	EEScaffold module publish -n CalendarFoundation -t $(currentTag) --no-lint-project-git --skip-build
	EEScaffold module publish -n CalendarRichTextEditor -t $(currentTag) --no-lint-project-git --skip-build
	git push origin $(currentTag)

i18n:
	EEScaffold module i18n -n Calendar
	EEScaffold module i18n -n CalendarFoundation
	EEScaffold module i18n -n CalendarRichTextEditor
	EEScaffold module i18n -n LarkTimeFormatUtils
	EEScaffold module i18n -n Todo
	EEScaffold module i18n -n TodoPlugin

i18n_edit:
	open Bizs/Calendar/configurations/i18n/i18n.strings.yaml

open:
	open CalendarDemo.xcworkspace

# 对比 demo 与 lark podfile 依赖区别, 需要 demo 与 ios-client 在同一层级，或者复制一份Podfile.lock到当前目录
compare:
	rake compare

compare_lark_and_update:
	./initLarkDependency.sh
    ifneq ($(commitOrPath)),)
		cd LarkDependency; git reset --hard origin/develop; git pull --rebase; git reset --hard $(commitOrPath); cd -
    else
		cd LarkDependency; git reset --hard origin/develop; git pull --rebase; git reset --hard $(larkBranchPath); cd -
endif
	
	./CleanPodfile.sh
	rake compare_and_update
