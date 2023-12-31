#!/bin/sh
#author: zhongtianren
#desc: 打包模板工程的读信页, 和写信页, 并更新替换到工程的包里

line="--------------"

cd ../MailSDK/Resources/mail-native-template
echo "$line 更新工程组件 $line"
yarn
# echo "$line 打包读信template $line"
# npm run build-all

echo "param is $1"

echo "$line 打包写信页editor $line"
if [ "$1" == "full" ]
then
    echo "$line 打包 editor 完全版白金究极体 $line"
    yarn build-full-editor
else
    echo "$line 打包 dll editor $line"
    yarn build-dll-editor
fi

echo "$line copy editor到工程内 $line"
cd public
cp plugins.html ../../SupportFiles/editor
cd ../../SupportFiles/editor
rm -rf mail_editor_index.html
mv plugins.html mail_editor_index.html
echo "$line 流程完成 $line"