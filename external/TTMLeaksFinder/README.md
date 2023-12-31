# TTMLeaksFinder - 今日头条定制版内存泄漏检测工具

## 接入文档

TTMLeaksFinder 已接入 Slardar，需和 Heimdallr 配套使用，接入文档：https://slardar.bytedance.net/docs/115/150/67718/

## Release Note

1.0.0 初版 TTMLeaksFinder

1.0.1 修复 assign 造成的 crash

2.0.0 TTMLeaksFinder 支持普通对象检测 https://bytedance.feishu.cn/docs/doccn5ktYC5PjLMRJtamDGqTBVd#

2.0.1 暴露 `+[TTMleaksFinder manualCheckRootObject:]` 手动触发接口

2.0.2 删除未下线的测试代码

2.0.3 修复关闭普通对象检测是，View VC 泄漏检测不到的问题

2.0.5 修复检测到 Swift 非 NSObject 对象遇到的 crash

2.0.7 修复 Heimdallr 头文件收敛编译不过问题

2.0.8 修复编译问题

2.0.9 修复交互式 dismissVC 的时取消操作造成的误报

2.0.10 废弃版本

2.0.11 

（1）【TTMLeaksFinder 误报优化】检测到 View VC 泄漏后再确认一次是否被显示 [文档](https://bytedance.feishu.cn/docs/doccnbagGb2bQ8IYRfQXHpKei4d#)

（2）【TTMLeaksFinder 问题追查】dealloc 触发异步操作 UI [文档](https://bytedance.feishu.cn/wiki/wikcn5UTALdH26WXvvFK2YKZZMc)

（3）普通对象增加 View Stack 信息，用于指示触发检测时 pop 的 VC

2.0.13 修复头文件引用等问题


【 API break 】

2.1.0

（1）重构。[重构内容文档](https://bytedance.feishu.cn/wiki/wikcn1lhSqF51hEOBetmnI0T9Sf)

（2）支持在 Slardar 上展示 block 符号

2.1.0 版本部分引用环的 id 和此前版本发生变化，如果你是从此前版本升级上来，可能有重复上报发生。


2.1.1 修复一些 bug

2.1.2 支持计算泄漏的大小

2.1.3——2.1.8 修复 Crash、Xcode12.5 源码编译报错、头文件引用等

2.1.9 提高 keyClass 准确性，其中 keyclass 用于自动分配泄漏


【 API break 】

2.1.9-alpha.0-swift 基于2.1.9版本支持了Swift 泄漏的检测，但暂时不支持闭包泄漏检测


## 后续会支持的功能

* 检测单例相关的泄漏
* 检测 Swift 闭包泄漏
* 关联对象的 key 上报
* 重复环合并




## Author

xushuangqing

## License

MLeaksFinder is available under the MIT license. See the LICENSE file for more info.
