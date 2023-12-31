set -e
# 测试数据
WORKSPACE=$(pwd)
# TAG="0.0.0.102"
# GIT_BRANCH=microapp_wulei

INFO_PLIST=$WORKSPACE/Example/Ecosystem/Info.plist
PODSPEC_FILE="$WORKSPACE/EEMicroAppSDK.podspec"

# 查找version版本并替换
OLD_TAG=$(sed -n "s/s\.version.*'\([0-9\.]*\)'/\1/p" $PODSPEC_FILE)

# 如果tag不存在，则根据tag_type来决定tag号
if [[ ! $TAG ]]; then
	TAG=$(node $WORKSPACE/hooks/modifyTag.js $OLD_TAG $TAG_TYPE)
fi

# 替换podspec文件中的版本号和framework地址
line=$(sed -n -e '/s\.version.*=/=' $PODSPEC_FILE)
sed -i '' "${line}s/'[0-9\.]*'/'$TAG'/g" $PODSPEC_FILE
# 替换配置文件用来提交代码
cp ~/.shell/config/push_config ~/.ssh/config && cp ~/.shell/config/.push_gitconfig ~/.gitconfig
# 提交podspec和infoplist的修改
git add $INFO_PLIST $PODSPEC_FILE
git commit -m "CI-Bot:auto update version to $TAG"
git push --set-upstream origin $GIT_BRANCH
git tag -a $TAG -m "CI-Bot:auto update version to $TAG"
git push origin $TAG
git clone git@code.byted.org:ee/pods_specs.git
cd $WORKSPACE/pods_specs/EEMicroAppSDK && mkdir $TAG && cd $TAG
cp $PODSPEC_FILE . && cd $WORKSPACE/pods_specs
git add . && git commit -m "[Update] Ecosystem ($TAG)" && git push origin master
cd $WORKSPACE && rm -rf pods_specs
# pod repo push byted-pods_specs EEMicroAppSDK.podspec --skip-import-validation --use-libraries --allow-warnings
# 恢复原始的配置文件，不影响kerberos认证
cp ~/.shell/config/config ~/.ssh/config && cp ~/.shell/config/.gitconfig ~/.gitconfig

PRIVATE_URL="https://oapi.zjurl.cn/open-apis/bot/hook/f5376582e107411eab1fb04399e6abe4"
curl -X POST \
	$PRIVATE_URL \
	-H "Content-Type: application/json" \
	-d '{
    "title": "小程序引擎TAG 构建成功",
    "text": "最新tag '$TAG'"
    }'
