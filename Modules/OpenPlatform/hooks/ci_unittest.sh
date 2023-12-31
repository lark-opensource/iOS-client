xcodebuild test -workspace Ecosystem.xcworkspace -scheme EcosystemTests -sdk "iphonesimulator"  -destination 'platform=iOS Simulator,name=iPhone X' | xcpretty && exit ${PIPESTATUS[0]}

