echo "大佬要拉docs还是bitable"
echo "1: docs"
echo "2: bitable"
read result
project=""
if [ $result == "1" ]
then
    cd ./docs
    echo "拉取docs i18n"
    project="Doc"
elif [ $result == "2" ]
    cd ./bitable
    echo "拉取bitable i18n"
    project="Bitable"
then
    echo "$prefix end"
else
    echo "让你输1或者2啊沙雕"
    exit 0
fi 
./i18n-client -project $project -platform iOS