# ShootsAPISocket

[![CI Status](https://img.shields.io/travis/chenzehua/ShootsAPISocket.svg?style=flat)](https://travis-ci.org/chenzehua/ShootsAPISocket)
[![Version](https://img.shields.io/cocoapods/v/ShootsAPISocket.svg?style=flat)](https://cocoapods.org/pods/ShootsAPISocket)
[![License](https://img.shields.io/cocoapods/l/ShootsAPISocket.svg?style=flat)](https://cocoapods.org/pods/ShootsAPISocket)
[![Platform](https://img.shields.io/cocoapods/p/ShootsAPISocket.svg?style=flat)](https://cocoapods.org/pods/ShootsAPISocket)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ShootsAPISocket is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ShootsAPISocket'
```

## Usage
### 1. 定义接口注册类
创建头文件，该类必须实现协议`BDIAPIHandler`，示例如下：  
```Objective-C
#import <Foundation/Foundation.h>
#import "ShootsAPISocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDIDemoAPIs : NSObject<BDIAPIHandler>

@end

NS_ASSUME_NONNULL_END

```

### 2. 实现接口注册类  
接口注册类通过routes方法返回接口路由列表，构造单个接口路由通过`BDIRPCRoute`的`CALL: respondTarget: action:`方法： 
```Objective-C
+ (instancetype)CALL:(NSString *)api respondTarget:(id)target action:(SEL)action;
```

一个完整的示例如下：  
```Objective-C
#import "BDIDemoAPIs.h"

@implementation BDIDemoAPIs

+ (nonnull NSArray<BDIRPCRoute *> *)routes {
    NSMutableArray *rpcRoutes = [NSMutableArray array];
    [rpcRoutes addObjectsFromArray:@[
        [BDIRPCRoute CALL:@"get_version" respondTarget:self action:@selector(handleGetVersion:)],
    ]];
    return rpcRoutes;
}

+ (BDIRPCResponse *)handleGetVersion:(BDIRPCRequest *)request
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *mainVersion = [[mainBundle infoDictionary] valueForKey:@"CFBundleVersion"];
    if(mainVersion == nil){
        mainVersion = @"";
    }
    NSDictionary *result = @{
        @"bundle_id": [[NSBundle mainBundle] bundleIdentifier],
        @"bundle_version": mainVersion
    };
    return [BDIRPCResponse responseToRequest:request WithResult:result];
}

@end
```
如上示例，注册的接口处理方法的收到的参数类型为`BDIRPCRequest`， 你可以通过`params`属性访问请求参数，请求参数为`NSDictionary`类型。

返回为`BDIRPCResponse`，通常使用`responseToRequest: WithResult`构造返回值，**可接收的result类型需为可json序列化的数据类型**。

### 4. 注册接口注册类
可参考如下代码在合适的地方注册你上面定义的的接口注册类
```Objective-C
[BDIScoketServer registerAPIHandlers:@[NSClassFromString(@"BDIDemoAPIs"), ...]] 
```

也可以给app增加如下环境变量实现自动注册：
```
SHOOTS_REGISTER_API_HANDLER_AUTOMATICALLY = 1
```
*warn*：自动注册会遍历所有app内部的类，在工程较大时可能会耗时较久，存在cpu突高的性能问题

### 5. 编译运行  
完成前述步骤，编译成功，接口即注册成功，下面开始进行接口调用的测试吧~  

### 6. 往客户端push消息  
该socket支持广播方式往客户端push消息，使用示例如下：  

```Objective-C
#import "BDISocketServer.h"

@implementation XXXX

- (void)xxxMethod
{
    [BDISocketServer pushMessage:@{@"key": @"push"}];
}

@end
```  
使用时直接引入`BDISocketServer`并调用`pushMessage:`消息发送广播即可，支持的消息类型需为可json序列化数据类型。

## Author

chenzehua, chenzehua.2020@bytedance.com

## License

ShootsAPISocket is available under the MIT license. See the LICENSE file for more info.
