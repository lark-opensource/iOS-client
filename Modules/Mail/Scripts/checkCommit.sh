#! /bin/bash
currentBranch=$(git branch | grep "*")
currentBranch=${currentBranch/" "/""}
currentBranch=${currentBranch/"*"/""}
#$1表示基branch[mailsdk:master, larkmail:feature/mail/develop]
if [[ $1 =~ "master" ]]
then
    #检查MailSDK
    cd "./"
else
    #检查LarkMail
    cd "../../ios-client"
    currentBranch="feature/mail/${currentBranch}"
    git checkout ${currentBranch}

fi
if [[ ${currentBranch} =~ "release" ]]
then
# 查找release分支和master分支的差异commit
commit="$1..${currentBranch}"

COMMITIDS=$(git log ${commit} --no-merges --pretty="%H" --author=tanghaojin --author=liutefeng --author=majunxiao --author=longweiwei --author=zhaoxiongbin --author=zhongtianren --author=yinjiupan)

# COMMITIDS切分成数组
IDS=(${COMMITIDS// /})
ARRAY=()

#检查这些commit在master分支是否含有，不含有的存入ARRAY
for ID in ${IDS[@]}
    do
    BRANCHTEXT=$(git branch --contains ${ID})
    BRANCHS=(${BRANCHTEXT// /})
    TAG=0
    for branch in ${BRANCHS[@]}
        do
        if [[ $branch =~ $1 ]]
        then
            TAG=1
        fi
        done
    if [[ ${TAG} == 0 ]]
    then
        ARRAY[${#ARRAY[*]}]=${ID}
    fi
    done

# 输出master没有的提交
for commit in ${ARRAY[@]}
    do
    str=$(git log --stat ${commit} -1 --pretty=oneline)
    show=1
    if [[ $str =~ "1 file changed" ]] && ([[ $str =~ "MailSDK.podspec" ]] || [[ $str =~ "Podfile" ]])
    then
        show=0
    fi
    if [[ $show == 1 ]] && [[ $str =~ "2 files changed" ]] && [[ $str =~ "Podfile" ]] && [[ $str =~ "Podfile.lock" ]]
    then
        show=0
    fi
    if [[ $show == 1 ]]
    then
        message=$(git log --pretty=format:"%s" ${commit} -1)
        echo -e "\033[31m $1没有这个commit，检查是否需要提交:\033[0m" "["${commit}  ${message} "]"
    fi
    done
fi


