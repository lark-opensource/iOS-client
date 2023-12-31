# Git Hook

## 作用
自动执行一些代码检查（swiftlint）、工程文件格式化（xunique）、ChangeID生成等逻辑。

## Set Up

run `sh ./hooks/install-hooks`

---
---

## 依赖工具介绍

### SwiftLint
- [Github: SwiftLint](https://github.com/realm/SwiftLint)
- [官方中文文档](https://github.com/realm/SwiftLint/blob/master/README_CN.md)

Swiftlint 是一个Swift代码风格检查工具，可以通过配置文件制定生效的规则，以及其具体数值配置。

在某个位置临时禁用某条规则的方式如下：

```swift
// swiftlint:disable force_cast
func youCode() -> Void {}
// swiftlint:enable force_cast
```

---

### xunique

- [Github: SwiftLint](https://github.com/truebit/xUnique)

xunique 是用来格式化工程文件的脚本。

> #### xUnique都做了什么
> - 替换所有UUID为项目内永久不变的MD5 digest
> - 删除所有多余的节点（一般是合并的时候疏忽导致的）

---
---

## 脚本介绍

### pre-commit
- 脚本位置: ios-client/hook/pre-commit
- 执行时机: before `git commit`
- 做了什么：
    - 格式化工程文件
    - Swiftlint 检查【仅检查变更的文件】
---
### post-commit
- 脚本位置: ios-client/hook/post-commit
- 执行时机: after `git commit`
- 做了什么: nothing
---
### commit-msg
- 脚本位置: ios-client/hook/commit-msg
- 执行时机: 生成 commit message 时
- 做了什么: 向 commit message 中追加Change-Id，以便Gerrit能够追踪某次提交。
---
### pre-push
- 脚本位置: ios-client/hook/pre-push
- 执行时机: before `git push`
- 做了什么:
---

### ~~changelog.sh~~
- 已废弃、可忽略

---
---

## Nest(旧称：AppCenter) 相关

### appcenter_prepare.sh
- 脚本位置: ios-client/hook/appcenter_prepare.sh
- 执行时机: **Nest** 执行构建 **prepare** 阶段
- 做了什么:
    - 更新 **RustPB（又称 SDK ）** 版本，具体版本号由 Nest 通过环境变量 **`SDK_VERSION`** 传递
    - 更新 **info.plist** 中的版本号版本，具体版本号由 Nest 通过环境变量 **`FULL_VERSION`** 传递
    - 去掉开启 **module stability** 的脚本，使用各个库的默认设置
    - 提交上述变更到 Git 仓库

---

### appcenter_release.sh

- 脚本位置: ios-client/hook/appcenter_release.sh
- 执行时机: **Nest** 在 **拉Release分支后** 调用
- 做了什么:
    - 调用`bin/increase_version.bash`,自动将master分支的版本号升高一个版本: **x.y.z-alpha** ==> **x.(y+1).z-alpha**, 并创建review

---

### appcenter_build.sh

- 脚本位置: ios-client/hook/appcenter_build.sh
- 执行时机: **Nest** 在 **构建阶段** 调用
- 做了什么:
    - 通过环境变量 **BUILD_CHANNEL** 决定 **export_method**
        -   | BUILD_CHANNEL |  export_method|
            | - | - |
            | inhouse | enterprise |
            | appstore | app-store |
    - 通过环境变量 **BUILD_CHANNEL**、 **BUILD_PRODUCT_TYPE** 决定 **LARK_BUILD_TYPE**
        -   | BUILD_CHANNEL | BUILD_PRODUCT_TYPE | LARK_BUILD_TYPE |
            | - | - | - |
            | inhouse | international | inhouse-oversea |
            | inhouse | domestic | inhouse |
            | inhouse | KA | inhouse |
            | inhouse | KA_international | inhouse-oversea |
            | appstore | international | international |
            | appstore | domestic | internal |
            | appstore | KA | internal |
            | appstore | KA_international | international |
    - 去处测试环境相关的配置
    - 根据环境变量 **BUILD_PRODUCT_TYPE** 和 **BUILD_CHANNEL** 决定 **fastlane** 构建参数
---
---

# Bin

###  ~~debug_cert.sh~~
---

### increase_version.bash
- 脚本位置: ios-client/bin/
- 执行时机: **Nest** 的 **prepare** 阶段
- 做了什么: 在拉取Release分支后，自动将master分支的版本号升高一个版本: **x.y.z-alpha** ==> **x.(y+1).z-alpha**, 并创建review
---

### ios-icon-generator.sh
- 脚本位置: ios-client/bin/
- 执行时机: **Nest** 构建KA包执行 `pod install` 之前
- 做了什么: 由一张 **1024 x 1024** 的资源图生成整套iOS图标
---

### replace_resource_for_international (shell)
- 脚本位置: ios-client/bin/
- 执行时机: 判断环境变量 **LARK_BUILD_TYPE** 的值，当值为 **inhouse-oversea** 或 **international** 时会执行该脚本
- 做了什么:
    - 将放置在 **ios-client/ReplaceResources/international** 的海外版本的资源替换到相应的位置。具体对应关系请参考下面的表格，路径是相对于 ios-client 的路径
        -   | 原始位置 | 目标位置 |
            | - | - |
            | international_resources/LarkMine_Notification | Pods/LarkAppResources/app_resources/Image.xcassets/LarkMine/Notification |
            | international_resources/LaunchImage | Lark/Assets.xcassets/LaunchImage/ |



### ~~switch_account_config.sh~~
---

### upload-ipa-release-preview.sh
- 不熟悉，待了解后补充
---

### upload-ipa-rutland （python）
- 脚本位置: ios-client/bin/
- 执行时机: Jenkins打包成功后
- 做了什么: 上传 **ipa** 到 **rutland** ，供生成安装链接。
---

### ~~~upload_compile_time.sh~~~
- 上传编译时间
---

### 符号还原
- 路径: ./bin
- 语言: perl
- 开发者: (仅上传， 来自Xcode)：@孔凯凯 
- 作用： 借助符号表可以还原Crash文件。
- 使用方式： symbolicatecrash  ${CRASH_FILE_PATH}  ${SYMBOL_PATH}
- 常见问题: 
  1. miss： DEVELOPER_DIR， 可以直接执行 export DEVELOPER_DIR=$(xcode-select --print-path)
  2. 符号化失败，SYMBOL_PATH要指定到二进制（*.dSYM/Contents/Resources/DWARF/NAME），很多网上的教程写的都是到 .dSYM 这个是不对的
  3. symbolicatecrash 前面不要加 sh
  4. 符号表不对，可以通过UUID核对，dwarfdump -u <PathToYourAppsDsym> 可以查看符号表的UUID，然后和Crash文件中的对比，说个比较简单的对比方案，能搜到就行。
  5. 系统符号还原不出来是因为Mac上没有对应的iOS的符号，找个同版本的真机连到机器上，xcode就会自动copy，这一步可能会有点耗时，但是是一次性工作，后面同版本无需重复。
---

### 国际化资源文件处理
- 路径:  ./bin/i18n
- 语言:  ruby & shell
- 开发者： @王孝华 
---

### KA 资源替换
- 路径:  ./bin/ka_resource_replace
- 语言:  ruby & shell
- 开发者： @孔凯凯 
- 依赖： ruby、optimus_ios
- 作用：在构建KA包时候将KA对应的资源从zeus上拉取下来并进行替换。
- 使用：在Fastlane构建KA包时候调用： ./bin/ka_resource_replace/start.sh；
- 常见问题: 
  1. 手动调用需要设置环境变量**BUILD_PRODUCT_TYPE** 为 ***KA*** ; **KA_TYPE** 为 想要测试的KA
--- 

### ./bin/impoort_infoplist_i18n.rb
- 语言: ruby
- 开发者： @王孝华 
---

### 路径:  ./bin/increase_version.bash
- 语言: bash
- 开发者： @王孝华 
---

### 生成iOS App Icon 
- 路径:  ./bin/ios-icon-generator.sh
- 语言: ruby、shell、swift、python
- 开发者： @孔凯凯 
- 作用： 由一张 1024 x 1024的资源图生成整套iOS图标
- 使用：bash  ios-icon-generator.sh  ${IMAGE_PATH} XXX.appiconset/
---

### Podfile 的依赖
- 路径:  ./bin/ruby_script
- 语言: ruby
- 开发者：@孔凯凯
- 使用：Podfile 中调用
---

### 图片压缩
- 路径:  ./bin/compress_png
- 语言: python
- 开发者：@黄健铭
- 使用：Podfile 中调用
