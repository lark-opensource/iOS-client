
CURRENT_VERSION=$(defaults read "$PWD"/Lark/Info.plist CFBundleShortVersionString)
IFS=. read -ra vers <<< "$CURRENT_VERSION"
# increase second version. third is 0-alpha
NEW_VERSION="${vers[0]}.$((vers[1] + 1)).0-alpha"
echo increase version "$CURRENT_VERSION => $NEW_VERSION"

for infoplist_path in 'Lark/Info.plist' 'Lark/Dev-Info.plist' 'ShareExtension/Info.plist' 'NotificationServiceExtension/Info.plist'; do
    plutil -replace CFBundleShortVersionString -string "$NEW_VERSION" "$infoplist_path"
done

# increase package.json
sed -i '' -e '/"version" *:/s/: *".*"/: "'"$NEW_VERSION"'"/' package.json
# increase appspec version
sed -i '' -e '/s.version *=/s/= *".*"/= "'"$NEW_VERSION"'"/' Lark.appspec

git add -u
git commit -m 'chore: increase version from '"$CURRENT_VERSION => $NEW_VERSION"
git push origin HEAD:refs/for/master${REVIEWERS:-%r=liuwanlin,r=qihongye,r=wangxiaohua,r=kongkaikai,r=zhaochen.09,r=lichen.arthur,r=supeng.charlie,r=ci-ee,r=dongzhao.stone,r=cuiguilin}

