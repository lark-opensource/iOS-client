# BDAlogProtocol

[![CI Status](https://img.shields.io/travis/胡波/BDAlogProtocol.svg?style=flat)](https://travis-ci.org/胡波/BDAlogProtocol)
[![Version](https://img.shields.io/cocoapods/v/BDAlogProtocol.svg?style=flat)](https://cocoapods.org/pods/BDAlogProtocol)
[![License](https://img.shields.io/cocoapods/l/BDAlogProtocol.svg?style=flat)](https://cocoapods.org/pods/BDAlogProtocol)
[![Platform](https://img.shields.io/cocoapods/p/BDAlogProtocol.svg?style=flat)](https://cocoapods.org/pods/BDAlogProtocol)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## 简介
BDAlogProtocol是提供给`基础库`使用的[BDAlog](https://code.byted.org/iOS_Library/BDALog)的中间层，不依赖BDAlog及任何库，因此BDAlogProtocol不用关心[BDAlog](https://code.byted.org/iOS_Library/BDALog)的任何逻辑，只需调用`BDAlogProtocol.h`提供宏写入log即可。BDAlogProtocol包含两部分逻辑：1、业务工程的podfile中引入[BDAlog](https://code.byted.org/iOS_Library/BDALog)，调用BDAlogProtocol提供写入log API最终由[BDAlog](https://code.byted.org/iOS_Library/BDALog)写入log。2、业务工程的podfile中没有引入[BDAlog](https://code.byted.org/iOS_Library/BDALog)，调用BDAlogProtocol提供写入log API会走一个空逻辑。

## 安装

BDAlogProtocol is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BDAlogProtocol'
```

## 使用教程

### 1. 引入头文件
````
#import "BDAlogProtocol.h"
````



### 2.写入log

``` javascript
/**
  *通过BDAlogProtocol.h提供宏写入log，宏的使用方式同NSLog
*/
//debug log
BDALOG_PROTOCOL_DEBUG(@"%@",@"hubo ------ debug"); 
//info log
BDALOG_PROTOCOL_INFO(@"%@%@",@"hubo -------- info",@"test");
//warn log
BDALOG_PROTOCOL_WARN(@"%@%@%@",@"hubo -------- warn",@"test",@"test"); 
//error log
BDALOG_PROTOCOL_ERROR(@"%@",@"hubo -------- error"); 
//fatal log
BDALOG_PROTOCOL_FATAL(@"%@",@"hubo -------- fatal");

//tag
BDALOG_PROTOCOL_DEBUG_TAG(@"tag",@"%@",@"hubo ------ debug");  
BDALOG_PROTOCOL_INFO_TAG(@"tag",@"%@",@"hubo -------- info");
BDALOG_PROTOCOL_WARN_TAG(@"tag",@"%@",@"hubo -------- warn");
BDALOG_PROTOCOL_ERROR_TAG(@"tag",@"%@",@"hubo -------- error");
BDALOG_PROTOCOL_FATAL_TAG(@"tag",@"%@",@"hubo -------- fatal");

//c和c++
ALOG_PROTOCOL_DEBUG("%s","ccccccccccccc---------");
ALOG_PROTOCOL_INFO("%s%s","ccccccccccccc---------","test");
ALOG_PROTOCOL_WARN("%s%s%s","ccccccccccccc---------","test","test");  
ALOG_PROTOCOL_INFO("%s","ccccccccccccc---------");
ALOG_PROTOCOL_FATAL("%s","ccccccccccccc---------");
    
//tag    
ALOG_PROTOCOL_DEBUG_TAG("tag","%s","ccccccccccccc---------");
ALOG_PROTOCOL_INFO_TAG("tag","%s","ccccccccccccc---------");
ALOG_PROTOCOL_WARN_TAG("tag","%s","ccccccccccccc---------");
ALOG_PROTOCOL_INFO_TAG("tag","%s","ccccccccccccc---------");
ALOG_PROTOCOL_FATAL_TAG("tag","%s","ccccccccccccc---------");
````

## Author

胡波, hubo.christyhong@bytedance.com

## License

BDAlogProtocol is available under the MIT license. See the LICENSE file for more info.
