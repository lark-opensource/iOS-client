#!/bin/sh

echo "🏀🏀🏀 开始 lint fix"

#修复简单的空格，多余行的问题，如果是代码规范问题，则不可通过该脚本修复
swiftlint --fix

echo "✅✅✅ 结束 lint fix"