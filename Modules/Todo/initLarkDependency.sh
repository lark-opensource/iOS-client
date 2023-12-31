#bin/sh
if [ -d ".git" ]; then
echo "### lark.git 已初始化"
else
echo "### 初始化 Lark.git.sparseCheckout"
git init LarkDependency
cd LarkDependency
git remote add -f origin git@code.byted.org:lark/ios-client.git
git config core.sparseCheckout true
mkdir .git/info
echo "Podfile.lock" >> .git/info/sparse-checkout
cd -
fi
