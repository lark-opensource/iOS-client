#!/usr/bin/env bash

# parse current directory
currentDir=$(dirname $0)
cd ${currentDir}
currentDir=$(pwd)

mailSDKNativeTemplatePath="${currentDir}/../MailSDK/Resources/mail-native-template"
mailSDKNativeTemplateSrcPath="${mailSDKNativeTemplatePath}/template"
swiftFilePath="${currentDir}/../MailSDK/Mail/Business/ReadMail/Bytetest/MailCheckContentManager.swift"
MailMessageListTemplateFilePath="${currentDir}/../MailSDK/Mail/Business/ReadMail/MailContentRender/MailMessageListTemplate.swift"
toast="编译"

#use the template_project_path.txt (which is ignored by git) to provide the specific template project path
#if template_project_path.txt is not exist, create one and open it for the user
readTemplateProjectPath() {
    #template project path on your machine
    templateProjectPathFile="$(pwd)/template_project_path.txt"
    if [ -f "$templateProjectPathFile" ];
    then
        #if file exist, read the path
        templateProjectPath=$(head -n 1 $templateProjectPathFile)
        #verify template project path
        if [ -d "$templateProjectPath" ];
        then
            echoStep "template project path: $templateProjectPath"
        else
            echoError "Invalid templateProjectPath: '$templateProjectPath'"
            echoError "Please fill the the template project path in template_project_path.txt"
            open -e $templateProjectPathFile
            exit 0
        fi
    else
        #file not exist, create one and open it
        echoError "没找到文件目录"
        echoError "请填上template工程路径 ${templateProjectPathFile}"
        touch $templateProjectPathFile
        echo "(Please replace this line with the template project path on your machine)" > $templateProjectPathFile
        open -e $templateProjectPathFile
        exit 0
    fi
}

copyTemplateFiles() {
    cp $templateProjectPath/template $mailSDKNativeTemplatePath
}

#print red error info to console
echoError() {
    echo -e "\033[1;31m 📧 -> $1 \033[0m"
}

#print blue step info to console
echoStep() {
    echo -e "\033[1;34m 📧 -> $1 \033[0m"
}

#print blue info to console
echoInfo() {
    echo -e "\033[1;34m 📧 -> $1 \033[0m"
}

#print green success info to console
echoSuccess() {
    echo -e "\033[1;32m 📧 -> $1 \033[0m"
}

buildAll() {
  toast="混淆编译"
  echoSuccess "默认使用release配置，生成混淆后js代码"
  echoStep "需要生成源码请加上 dev 参数"
  echoStep "删除当前SDK内template文件 ${mailSDKNativeTemplateSrcPath}"
  rm -r $mailSDKNativeTemplateSrcPath

  echoStep "准备编译template代码，目录： ${templateProjectPath}"
  cd ${templateProjectPath}
  npm run build-all
  npm run build-dark-mode

  cd ${currentDir}
  echoStep "准备复制template代码到 MailSDK template目录"
  cp -r $templateProjectPath/template $mailSDKNativeTemplatePath
  cd ${templateProjectPath}/dark-mode
  cp $templateProjectPath/dark-mode/dist/dark_mode_sdk.min.js $mailSDKNativeTemplatePath/template/dark_mode_sdk.min.js
  echoSuccess "更新template完成"

  
  
  buildAutoTest
}

buildAllDev() {
  toast="源码编译"
  echoSuccess "使用dev，生成源码"
  echoStep "删除当前SDK内template文件 ${mailSDKNativeTemplateSrcPath}"
  rm -r $mailSDKNativeTemplateSrcPath

  echoStep "准备编译template代码，目录： ${templateProjectPath}"
  cd ${templateProjectPath}
  npm run build-all-dev
  npm run build-dark-mode
  cd ${currentDir}
  echoStep "准备复制template代码到 MailSDK template目录"
  cp -r $templateProjectPath/template $mailSDKNativeTemplatePath
  cd ${templateProjectPath}/dark-mode
  cp $templateProjectPath/dark-mode/dist/dark_mode_sdk.min.js $mailSDKNativeTemplatePath/template/dark_mode_sdk.min.js
  echoSuccess "更新template完成"
  
  buildAutoTest
}

buildAutoTest() {
  echoStep '开始更新自动化测试文件'
  cd ${currentDir}
  if [ -e ${swiftFilePath} ]
  then
    echoStep "find swift file at ${swiftFilePath}"
    sed '/MailSwift/d' ${templateProjectPath}/auto_test/checkContent.js > ${swiftFilePath}
    echoSuccess '自动化文件更新成功'
  else
    echoError "No Found at ${swiftFilePath}"
  fi
}

# Main
readTemplateProjectPath

if [ -z $1 ]; then
  buildAll
else
  case $1 in
    dev)
      buildAllDev
      ;;
    *)
      echoError "错误参数，默认混淆"
      buildAll
      ;;

  esac
fi

echoSuccess "${toast}-全部搞定"
