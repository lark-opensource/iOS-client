WORKSPACE=$(pwd)
# IS_LARK_DEV=true

# 获取到ipa的包名称
IPA_NAME=$(find ${WORKSPACE}/archives -name "*.ipa" -maxdepth 1 | xargs basename)
NEW_IPA_NAME=Ecosystem
cp ${WORKSPACE}/archives/$IPA_NAME ${WORKSPACE}/archives/$NEW_IPA_NAME.ipa
# 上传ipa包
/usr/local/bin/npm install --save request
/usr/local/bin/node ${WORKSPACE}/hooks/ipa_upload.js "${BUILD_URL}artifact/hooks/package_index.html" $NEW_IPA_NAME $GIT_BRANCH
