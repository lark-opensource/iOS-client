# 文档

## 发版相关
[Lark release notes](https://bytedance.feishu.cn/space/folder/ZnMqk0SllnWRDm82)

### 企业包发版
[发版流程](https://wiki.bytedance.net/pages/viewpage.action?pageId=125584030)
[Inhouse包发版流程](https://bytedance.feishu.cn/space/doc/doccnkrzZjkXdycZcidtWr)

### App Store 相关

[App Store发版流程](https://bytedance.feishu.cn/space/doc/doccnaBZfQEgXnzBm5DunC)
[Apple Store发版体积](https://bytedance.feishu.cn/space/sheet/shtcnyhKEWGMAlwwwdJm0j)
[Lark App Store 版本日志](https://bytedance.feishu.cn/space/sheet/shtcngvZJuyxwnPteDzneM)
[Lark上架App Store被拒Case列表](https://bytedance.feishu.cn/space/doc/doccnfRofLPXcBM6vrHdlW)


## 在线代码地址

<https://ee.byted.org/madeira/repo/lark/LarkMessenger/>

## Rakefile介绍
- rake version
  - 输出当前LarkMessenger的版本
- rake integrate
  - 将当前LarkMessenger的版本同步到ios-client（需要ios-client和LarkMessenger在同一目录）。
- rake patch
  - 升级LarkMessenger到下一个patch版本
  - 如果当前是LarkMessenger是alpha版本，则去掉alpha
    -  e.g. 3.18.0-alpha.3 => 3.18.0
  - 如果当前是LarkMessenger是正式版本，则patch位（第三位）+1
    - e.g.  3.18.0 => 3.18.1
- rake alpha
  - 升级LarkMessenger到下一个alpha版本
  - 如果当前是LarkMessenger是alpha版本，则alpha 位+1
    -  e.g. 3.18.0-alpha.3 => 3.18.0-alpha.4
  - 如果当前是LarkMessenger是正式版本，则minor位（第二位）+1，再补上alpha.0
    - e.g.  3.18.0 => 3.19.0.alpha.0
- rake change_version
  - 修改LarkMessenger的版本到指定版本 e.g. rake change_version version=xxx.xx.x
- rake publish
  - 发布LarkMessenger中所有Pod
- rake compare
  - 使用LarkMessenger仓库和ios-client仓库中的Podfile.lock文件，来比较两个工程中依赖pod依赖的不同。在命令行输出结果