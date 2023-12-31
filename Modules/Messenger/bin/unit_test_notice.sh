if [ $1 == "true" ]; then
TITLE="单测运行成功"
Test_URL="测试报告地址：${BUILD_URL}/Test_20Report/\n"
CONTENT="${Test_URL}"
else
TITLE="单测运行失败，请及时处理。"
BUILD_URL="构建地址：${BUILD_URL}\n"
CONTENT="${BUILD_URL}"
fi

curl -X POST \
-H "Content-Type: application/json" \
-d '{"title": "'"$TITLE"'", "text": "'"$CONTENT"'"}' \
https://open.feishu.cn/open-apis/bot/hook/8e3123a8afcd4fe9ba311e3608c150a0