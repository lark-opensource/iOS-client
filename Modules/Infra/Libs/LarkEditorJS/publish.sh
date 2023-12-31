#usr/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"
cd $DIR

echo 当前目录: $(pwd)

bundle exec eesc module publish --skip-build --no-lint-project-git -n LarkEditorJS