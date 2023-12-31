#!/bin/bash
echo "请输入所需要对比的两个分支名，请保证本地的两个分支都是最新代码"

read -p "new branch: " newBranch #feature/litao/3.37_code_count_detail
read -p "old branch: " oldBranch  #release/3.36

git log ${newBranch}...${oldBranch} --numstat --date=format:'%Y-%m-%d %H:%M:%S' >> git_log.txt

# 提取出所有作者
cat git_log.txt | grep "Author:" >> authors.txt
sort authors.txt | uniq | cut -c 9- >> authors_uniq.txt

echo '\n计算中...骚等一会...'

statisticsGitCommit() {
    cat authors_uniq.txt | while read author
    do
        git log --author="${author}" ${newBranch}...${oldBranch} --pretty=tformat: --numstat | grep ".swift" | gawk '{ add += $1 ; subs += $2 ; loc += $1 - $2; } END { printf "\033[36m%s\033[0m\t\033[32m+%s\033[0m\t\033[31m-%s\033[0m\t",loc, add, subs; loc = 0; add = 0; subs = 0; }'
        printf "| ${author}\n"
    done
}

statisticsPngSizeChanges() {
    cat authors_uniq.txt | while read author
    do
        git log --stat --author="${author}" ${newBranch}...${oldBranch} | grep ".png" >> temp.txt
        cat temp.txt | gawk '{ loc += ($6 - $4)/1024; } END { printf "%.3f\t" , loc }'
        printf "${author}\n"
        rm temp.txt
    done
}

statisticsGitCommit >> git_commit_sta_temp.txt

echo '\nswift文件代码变化统计结果：(lines)'
echo '\033[36mdiff\033[0m\t\033[32madd\033[0m\t\033[31mremove\033[0m\t| author'

sort -nr git_commit_sta_temp.txt

echo '\n图片尺寸(KiB)变化统计结果：'
statisticsPngSizeChanges >> git_png_size_changes.txt
sort -nr git_png_size_changes.txt

removeTempFiles() {
    rm git_log.txt
    rm authors.txt
    rm authors_uniq.txt
    rm git_commit_sta_temp.txt
    rm git_png_size_changes.txt
}

removeTempFiles
