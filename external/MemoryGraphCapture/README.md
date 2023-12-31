# MemoryGraphCapture

[![CI Status](https://img.shields.io/travis/Chao Wei/MemoryGraphCapture.svg?style=flat)](https://travis-ci.org/Chao Wei/MemoryGraphCapture)
[![Version](https://img.shields.io/cocoapods/v/MemoryGraphCapture.svg?style=flat)](https://cocoapods.org/pods/MemoryGraphCapture)
[![License](https://img.shields.io/cocoapods/l/MemoryGraphCapture.svg?style=flat)](https://cocoapods.org/pods/MemoryGraphCapture)
[![Platform](https://img.shields.io/cocoapods/p/MemoryGraphCapture.svg?style=flat)](https://cocoapods.org/pods/MemoryGraphCapture)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

MemoryGraphCapture is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MemoryGraphCapture'
```

## Author

Chao Wei, chao.wei@bytedance.com

## License

MemoryGraphCapture is available under the MIT license. See the LICENSE file for more info.

## 更新记录
* 1.4.2 
     * 修复了若干可能会导致MemoryGraph采集过程中卡死的问题
     * 增加降级case对于AutoreleasePoolPage的识别
* 1.4.1 1.4.0-bug-fix,修改获取元类方法，可开启enable_leak_node_calibration开关
* 1.4.0 【API break】要配合升级Heimdallr版本0.8.6-rc.0及以后
     * 降级case实现vm:stack符号化；
     * 实现泄漏内存节点引用关系校准，增加oc类运行时内存节点的引用关系(>=ios14)，默认功能关闭，支持Slardar配置下发；(1.4.0开关不可开启,bug修复版本为1.4.1)
* 1.3.9 bug废弃 
* 1.3.8 废弃
* 1.3.7 bug废弃
* 1.3.6 修复在某些情况下c++对象不能正确识别的bug
* 1.3.5 增加降级case的区分以及打点上报，需要配合升级Heimdallr版本0.8.2及以后
* 1.3.4  1.3.2.1-bugfix代码合并
* 1.3.3 增加对于VM:Stack内存结点的符号化，显示对应的线程名/GCD队列名/NSOperationQueue，需要依赖Heimdallr SDK版本更新，版本号后续补充
* 1.3.2.1-bugfix 取消C++静态对象的析构，防止可能出现的APP退出时崩溃
* 1.3.2 修复在iOS15-arm64e(xr及以后)机型中由于PAC(指针校验机制)导致的异常，metrickit定性为卡死
* 1.3.1 bug废弃
* 1.3.0 采集时增加超时检测功能，避免时间过长导致的卡死，默认超时时间为8s，支持Slardar配置下发，配置下发需要结合Heimdallr SDK
* 1.2.9 修复swift-demangle功能在非swift项目中的编译问题
* 1.2.8 
  * 增加内存二次校验，准备挂起线程前和挂起线程之后的内存差值过大则取消本次采集。
  * 增加swift-demangle功能
  * 优化获取全部OC类为获取全部实现了的OC类  `objc_getClassList->objc_copyRealizedClassList`
* 1.2.7 修复arm64e机型中CoreFoundation对象无法正确识别的问题

