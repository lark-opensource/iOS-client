# /bin/sh
# author: xurunkang
### sync version from podspecfile


## 1. 找到文件
podDirect=$(cd `dirname $0`; cd ..; pwd)
podName='MailSDK.podspec'
fileName='Business/Docs/DocsCore/Common/MailCore.swift'

src_pod_spec=${podDirect}/${podName}
sourefileName=${podDirect}/${fileName}
if [ ! -f "$src_pod_spec" ]
then 
    echo "pod spec ${src_pod_spec}  not found"
    exit 1
else 
    echo "found podspec ${src_pod_spec}"
fi

if [ ! -f "$sourefileName" ]
then 
    echo "version source file ${sourefileName} not found"
    exit 1
else 
    echo "found version source file ${sourefileName}"
fi

## 2. 找到podspec 中的version
pod_spec_version=`grep -RE 's.version *=' ${src_pod_spec} | cut -f 2 -d= | cut -f 2 -d\'`
echo "version in spec file: ${pod_spec_version}"

if [ -z "$pod_spec_version" ]; then 
    echo "version in spec file  is empty" 
    exit 1
fi

## 3. 找到sourcefile中的version
config_version=`grep let\ versionString\ = ${sourefileName} | cut -f 2 -d= | cut -f 2 -d\"`
echo "before replace verison in source file is ${config_version}"

if [ -z "$config_version" ]; then 
    echo "version in source file is empty" 
    exit 1
fi

## 4. 如有必要，替换一下
if [[ ${config_version} != ${pod_spec_version} ]]; then
	sed -i "" "s/let versionString = .*/let versionString = \"${pod_spec_version}\"/" ${sourefileName}
fi

## 5.验证一下
config_version_new=`grep let\ versionString\ = ${sourefileName} | cut -f 2 -d= | cut -f 2 -d\"`
echo "after replace verison in source file is ${config_version_new}"
if [[ ${config_version_new} != ${pod_spec_version} ]]; then
    echo "after replace verison in source file is not same"
    exit 1
fi