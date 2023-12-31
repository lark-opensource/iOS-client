#!/bin/bash

curPath=$(cd "$(dirname "$0")";pwd)
srcPath="${curPath}/../Timor"
basePath="${srcPath}/apidoc"
indexPath="${basePath}/dist/index.html"

placeHolder="<br/>"
sed -i "" "s#.*<span class=\"type type__.*#${placeHolder}#g" $indexPath
sed -i "" "s#.*<pre class=\"prettyprint language-html.*#${placeHolder}#g" $indexPath
