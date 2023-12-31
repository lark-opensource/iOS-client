#!/bin/bash

curPath=$(cd "$(dirname "$0")";pwd)
srcPath="${curPath}/../Timor"
basePath="${srcPath}/apidoc"
docPath="${basePath}/tt-doc"
distPath="${basePath}/dist"

apidoc -i $srcPath -c $basePath -e "main\\.js" -o $distPath
