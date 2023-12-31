cd fastlane
bundle install
bundle exec bundle exec fastlane ios UPDATE_SETTING
cd ..
git add .
git commit -m "更新LarkSeetting"
git push origin HEAD:origin/develop
