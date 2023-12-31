fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios build_lark
```
fastlane ios build_lark
```

### ios execute_cocoapods
```
fastlane ios execute_cocoapods
```
Execute Cocoapods
### ios lint
```
fastlane ios lint
```
Use Pod Lib Lint to check the pod spec
### ios unittest
```
fastlane ios unittest
```
Scan and lint the swift source code
### ios check
```
fastlane ios check
```
check a merge reqeust
### ios mrcheck
```
fastlane ios mrcheck
```
open a merge request
### ios generate
```
fastlane ios generate
```
generate release notes
### ios deploy
```
fastlane ios deploy
```
Deploy the pod by EEScaffold
### ios rebase
```
fastlane ios rebase
```
rebase
### ios postReviewStatus
```
fastlane ios postReviewStatus
```
send review status
### ios getReviewStatus
```
fastlane ios getReviewStatus
```
get review status
### ios merge
```
fastlane ios merge
```
merge
### ios execute_sonar
```
fastlane ios execute_sonar
```
execute sonar scanner
### ios send_sonar_info
```
fastlane ios send_sonar_info
```

### ios package_clone_lark
```
fastlane ios package_clone_lark
```
upload dsym zip to slardar

upload ipa to tos
### ios send_bot_notify
```
fastlane ios send_bot_notify
```

### ios package_build_lark
```
fastlane ios package_build_lark
```

### ios NeoBeta
```
fastlane ios NeoBeta
```

### ios ee_build_enterprise_ipa
```
fastlane ios ee_build_enterprise_ipa
```

### ios smoke_test
```
fastlane ios smoke_test
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
