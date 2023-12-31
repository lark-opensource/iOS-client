#bin/sh
echo '### 清洗 Calendar.Podfile 统一为单引号'
sed -i Podfile $'s/\"/\'/g' Podfile
rm -rf PodfilePodfile