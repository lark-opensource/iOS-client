
CURRENT_VERSION=$(plutil -p Lark/Info.plist | awk -F '"' '/CFBundleShortVersionString/ { print $4 }')
IFS=. read -ra vers <<< "${CURRENT_VERSION}"

# increase second version. third is 0-alpha
NEW_VERSION_STR=${SEAL_VERSION_NEST_VERSION:-${vers[0]}.$((vers[1] + 1)).0}

NEW_VERSION="${NEW_VERSION_STR}-alpha"
echo increase version "${CURRENT_VERSION} => ${NEW_VERSION}"
agvtool new-marketing-version "${NEW_VERSION}"

# 同时更新 Messenger 版本号
pushd Modules/Messenger/

CURRENT_VERSION_MESSENGER=$(plutil -p LarkMessengerDemo/Info.plist | awk -F '"' '/CFBundleShortVersionString/ { print $4 }')
IFS=. read -ra vers <<< "${CURRENT_VERSION_MESSENGER}"

NEW_VERSION_MESSENGER="${NEW_VERSION_STR}-message"
echo increase version "${CURRENT_VERSION_MESSENGER} => $NEW_VERSION_MESSENGER"
agvtool new-marketing-version "${NEW_VERSION_MESSENGER}"

popd

# increase package.json
sed -i '' -e '/"version" *:/s/: *".*"/: "'"${NEW_VERSION}"'"/' package.json
# increase appspec version
# sed -i '' -e '/s.version *=/s/= *".*"/= "'"${NEW_VERSION}"'"/' Lark.appspec

git add -u
if [[ -n "$(git diff-index --cached --name-only HEAD)" ]]; then
    git commit -m "Increase version from Lark:${CURRENT_VERSION} => ${NEW_VERSION}; Messenger: ${CURRENT_VERSION_MESSENGER} => ${NEW_VERSION_MESSENGER};"
    git pull --rebase
    git push origin HEAD:develop
fi
