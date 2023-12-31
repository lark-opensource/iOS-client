#!/bin/sh
#author: guotenghu
#desc: 分析lark日志中和docs相关的信息
#https://docs.bytedance.net/doc/gH2EwGzM5XtwRvijUvsXTh

###################
# 参数读取
# set -ex
LOG_FILE_PATH=$1

echoRed() {
  echo "\033[31m$1\033[0m"
}


# 判断传参
if [[ ! -n "$1" ]]; then
  echoRed '缺少 log path'
  exit
fi

#获取输入输出路径
fullname="${LOG_FILE_PATH##*/}"
extension="${fullname##*.}"
filename="${fullname%.*}"

outname=${filename}_analysis.$extension
outpath=output/${filename}

mkdir -p output/${filename}
grep Module.Docs $LOG_FILE_PATH > $outpath/docs.log
cd ${outpath}

echo "sdkVersion:" > basicInfo.log
cat docs.log | sed -n '/SDK /p' >> basicInfo.log
echo "------" >> basicInfo.log

echo "networkInfo:" >> basicInfo.log
cat docs.log | sed -n '/curentNet:/p' >> basicInfo.log
echo "------" >> basicInfo.log


echo "scminfo:" >> basicInfo.log
cat docs.log | sed -n '/currentInfo envent js: scm/p' >> basicInfo.log
echo "------" >> basicInfo.log


#分割为每一次启动
awk '/SDK Init/{n++}{filename = "lanch" n ".log"; print >filename }' docs.log

files=`ls lanch*.log`
# 处理每一次启动
lanchtime=1
for filename in $files
do
    echo analysis lanch ${lanchtime} begin
   subDir=`basename ${filename} .log`
   mkdir -p $subDir
#    echo $subDir
   mv $filename $subDir/$filename
   cd $subDir

   ##基本信息
   echo "sdkVersion:" > basicInfo.log
   cat ${filename} | sed -n '/SDK /p' >> basicInfo.log
   echo "------" >> basicInfo.log

    echo "networkInfo:" >> basicInfo.log
   cat ${filename} | sed -n '/curentNet:/p' >> basicInfo.log
   echo "------" >> basicInfo.log


   echo "scminfo:" >> basicInfo.log
   cat ${filename} | sed -n '/currentInfo envent js: scm/p' >> basicInfo.log
   echo "------" >> basicInfo.log

   echo "open file:" >> basicInfo.log
    cat ${filename}| sed -n '/start open/p' >> basicInfo.log
    echo "------" >> basicInfo.log



    #分割为每一次文件打开
    awk '/start open /{n++}{filename = "openfile" n ".log"; print >filename }' $filename
    # ls
    openfiles=`ls openfile*.log`

    opentime=0
    for openfile in $openfiles 
    do 
        echo analysis open file ${opentime} begin
        # echo $openfile
        subDirOpenfile=`basename ${openfile} .log`
        mkdir -p $subDirOpenfile
        # echo $subDirOpenfile
        mv $openfile $subDirOpenfile/$openfile
        cd $subDirOpenfile
        echo "open file time line:" > opentimeline.log
        cat ${openfile} | sed -n '/start open /p' >> opentimeline.log
        cat ${openfile} | sed -n '/ReportService/p' >> opentimeline.log
        cat ${openfile} | sed -n '/js log:/p' >> jslog.log
        cd ..
        echo analysis open file ${opentime} end
        opentime=`expr $opentime + 1`
    done

   echo "------" >> basicInfo.log


    cd ..
    echo analysis lanch ${lanchtime} end
    lanchtime=`expr $lanchtime + 1`
    echo "------------------"
done

echo analysis all end



