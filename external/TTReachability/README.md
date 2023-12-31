# TTReachability

## 简介

本组件库，是基于苹果的[官方Reachability教程](https://developer.apple.com/library/archive/samplecode/Reachability/Introduction/Intro.html)，在此基础上进行了优化并添加一些相关功能的网络连通性检测库，并无额外的依赖，适用于比较通用的场景。

目前主要包含了三个功能：连通性检测，蜂窝制式检测，以及网络权限检测。

## 特性

- [x] 支持当前网络连通性检测（WiFi/蜂窝）
- [x] 支持判断当前移动蜂窝网络制式（5G/4G/3G/2G）
- [x] 支持判断双卡设备，指定SIM卡的可用性和蜂窝网络制式，运营商信息
- [x] 支持检测国行机型的蜂窝+WiFi访问权限

## 版本要求

+ iOS 7.0+（强烈建议iOS 9+）
+ macOS 10.9+
+ tvOS 9.0+
+ Xcode版本：11.0+（Xcode 10请使用老版本或者0.x）

## 运行Example工程

这里建议下新的接入方，参考一下Demo跑起来（用真机，证书选择个人证书），理解一下基本的常见用法和姿势～

+ clone工程
+ 切换到`Example`目录
+ `pod install`
+ 打开Workspace，选中`TTReachability-Example`的Scheme，点击Run
+ 如果是macOS，选中`TTReachability-Example`的Scheme，点击Run

## 运行单元测试

+ 执行和Example一样的步骤
+ 打开Workspace，选中`TTReachability-Tests`的Scheme，点击Test

## 接入方式

CocoaPods接入方式支持：

+ [x] 源码支持
+ [x] 二进制支持

Swift支持：

+ [x] 需要使用Modular Header

## 代码示例

+ 获取连通性状态

```objectivec
TTReachability *reach = [TTReachability reachabilityForInternetConnection];
NetworkStatus status = [reach currentReachabilityStatus]; // 立即同步获取当前联通性状态
```

+ 检测某一个域名的连通性

```objectivec
// 检测对toutiao.com的连通性
TTReachability *reach = [TTReachability reachabilityWithHostName:@"toutiao.com"];
[reach startNotifier];
```

+ 接收某一个域名连通性变化的通知

```objectivec
// 注意这里object，传入指定域名的TTReachability对象，以过滤其他域名变化的通知
// 注意通知不保证在主线程触发（取决于调用startNotifier的线程的RunLoop）
// 着重提示，千万不要在NSNotificationCenter这里的API的`queue`参数中填入mainQueue，可能导致主线程死锁，传入nil（即在发送方线程回调），然后自己根据需要进行queue切换即可
[[NSNotificationCenter defaultCenter] addObserverForName:TTReachabilityChangedNotification object:reach queue:nil usingBlock:^(NSNotification * _Nonnull note) {
    TTReachability *reach = note.object;
    NetworkStatus status = reach.currentReachabilityStatus;
    // 这里是当前的连通性
}];
```

+ 过滤指定类型的连通性变化的通知

```objectivec
// 如果你只关心指定域名或者本地的网卡连通性，可以不自己初始化实例，借助已有的实例的通知，然后过滤对应的类型即可
// 注意这里object，传入nil，接受所有对象发来的通知
[[NSNotificationCenter defaultCenter] addObserverForName:TTReachabilityChangedNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
    TTReachability *reach = note.object;
    if (!reach.isInternetConnection) {
        // 只关心本地网卡的变化，也可以判断指定域名
        return;
    }
    NetworkStatus status = reach.currentReachabilityStatus;
    // 这里是本地网卡的连通性
}];
```

+ 判断当前网络是WiFi环境

```objectivec
if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWiFi) {
    // 当前WiFi联通
}
```

+ 判断指定SIM卡可用性

```objectivec
NSArray *services = [TTReachability currentAvailableCellularServices];
if ([services containsObject:@(TTCellularServiceTypePrimary)]) {
    // 主卡可用
}
if ([services containsObject:@(TTCellularServiceTypeSecondary)]) {
    // 副卡可用
}
```

+ 判断指定SIM卡的网络制式（注意这不等价于用户正在使用5G/4G连接，见下）

```objectivec
// 这里检测主卡
switch ([TTReachability currentCellularConnectionForService:TTCellularServiceTypePrimary]) {
    case TTCellularNetworkConnection5G:
    // 5G
    case TTCellularNetworkConnection4G:
    // 4G
    case TTCellularNetworkConnection3G:
    // 3G
    case TTCellularNetworkConnection2G:
    // 2G
    case TTCellularNetworkConnectionUnknown:
    // 目前未知制式，6G?
    case TTCellularNetworkConnectionNone:
    // 无蜂窝网络
}
```

+ 检查指定SIM蜂窝数据连接的制式

```objectivec
if ([[TTReachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWWAN) {
    // 首先保证蜂窝连通
    switch ([TTReachability currentCellularConnectionForService:TTCellularServiceTypePrimary]) {
        case TTCellularNetworkConnection5G:
        // 5G数据连接
        case TTCellularNetworkConnection4G:
        // 4G数据连接
        case TTCellularNetworkConnection3G:
        // 3G数据连接
        case TTCellularNetworkConnection2G:
        // 2G数据连接
        case TTCellularNetworkConnectionUnknown:
        // 目前未知制式，5G?
        default:
        // 这里应该不会出现TTCellularNetworkConnectionNone
    }
}
```

+ 检查当前网络权限

```objectivec
if ([[TTReachability reachabilityForInternetConnection].currentNetworkAuthorizationStatus == TTNetworkAuthorizationStatusWLANAndCellularNotPermitted) {
    // 国行机型禁用了蜂窝+WiFi权限
}
```

+ 获取CTCarrier运营商

```objectivec
// 获取主卡的运营商信息
CTCarrier *carrier = [TTReachability currentCellularProviderForService:TTCellularServiceTypePrimary];
NSString *carrierName = carrier.carrierName; // 中国联通
// 获取用户配置的流量卡的运营商信息(iOS 13以上有效)
CTCarrier *dataCarrier = [TTReachability currentCellularProviderForDataService];
// 获取按照优先级排列的数组，当前使用的数据流量卡是最高优先级，可能有0，1，2个元素的情形。具体参考文档的规则
NSArray<CTCarrier *> *carriers = [TTReachability currentPrioritizedCellularProviders];
```

+ 获取CTRadioAccessTechnology制式

```objectivec
// 获取主卡的详细制式信息
// 仅需要单纯的5G/4G/3G/2G请用`currentCellularConnectionForService:`
NSString *technology = [TTReachability currentRadioAccessTechnologyForService:TTCellularServiceTypePrimary];
if ([technology isEqualToString:CTRadioAccessTechnologyLTE]) {
  // LTE
} else if ([technology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
  // WCDMA
}
```

+ 一些配置项

```objectivec
TTReachability.statusCacheConfigBlock = ^double{
    return 10; // 连通性状态缓存超时时间为10秒
};

TTReachability.internetConnectionNotifyRunLoop = NSRunLoop.mainRunLoop; // reachabilityForInternetConnection使用主RunLoop和mainQueue来监听和发出通知
```

+ 一些工具方法

```objectivec
NSDictionary<NSString *, NSString *> *addresses = [TTReachability currentIPAddresses];
NSString *wifiIPv4 = addresses[@"en0/ipv4"]; // 获取指定端口的IP地址，IPv4
NSString *wifiIPv6 = addresses[@"en0/ipv6"]; // 获取指定端口的IP地址，IPv6
NSString *baiduIPv4 = [TTReachability IPAddressOfHostName:@"www.baidu.com" protocolType:TTNetworkProtocolTypeIPv4]; // 进行DNS解析，IPv4
NSString *baiduIPv6 = [TTReachability IPAddressOfHostName:@"www.baidu.com" protocolType:TTNetworkProtocolTypeIPv6]; // 进行DNS解析，IPv6
```

# 下游Pod库作者常见问题

### 如何书写Pod Dependency

如果你的Pod库属于上层业务库，建议业务库不写明dependency的版本号，使用[组件平台的容器打包](http://cloud.bytedance.net/mobile/docs/Platform/container.html)来处理；

如果是标准库，请务必参考[iOS标准库代码标准](https://bytedance.feishu.cn/space/doc/doccn6u3AImwpoinTdu6Tp#4i9Xel)，TTReachability遵循语义版本号，请使用相对宽松依赖来引入

```
s.dependency "TTReachability", "~> x.y"
```

注：特殊情况下（见后文），也可以使用`>=`来指定依赖

### 关于依赖的版本号选择

具体版本号，取决于你使用的API引入的版本，参考下文的历史版本记录，这里列出几个关键点

+ `~> 0.1`:和Apple本身的Demo API基本一致，提供连通性检测方法，蜂窝状态方法
+ `~> 0.1.7`:提供了检测蜂窝权限的接口
+ `~> 0.2`:支持双卡模式的对应API
+ `~> 0.3`:新增了便携方法，枚举来访问当前蜂窝数据具体制式
+ `~> 0.4`:优化了Swift的接口和枚举
+ `~> 0.5`:暴露了能获取CTCarrier的接口
+ `~> 1.0`:使用了新的NotificationName以避免符号冲突，删除旧的枚举命名，Break改动
+ `~> 1.1`:增加了能够拿到当前用户配置的流量卡，对应的CTCarrier的接口
+ `~> 1.2`:增加了一个便携方法，可以拿到单双卡的CTCarrier按照优先级排列的数组，可以用于一些通用上报场景
+ `~> 1.3`:支持了获取CTRadioAccessTechnology的相关API，如果4G/3G满足不了需求的话用这个接口
+ `>= 0.5.3`:由于1.0 Break了通知名，如果下游库需要这一时间段内同时兼容0.x版本和1.x版本，请使用这个依赖，并且使用`TTReachabilityChangedNotification`通知名即可。另外，如果需要依赖后续功能版本，请从版本记录里面，找到对应的兼容版本，依然使用`>=`匹配


# 版本记录

 版本号 | 升级日志 
 ------ | -----------------
 1.8.6 | 修复iOS 15+出现的获取数据流量卡信息小概率Crash的问题，加锁访问。更新最低Xcode版本为Xcode 11
 1.8.5 | 修复由于static变量名称导致的runloop配置失效的问题
 1.8.4 | 修复蜂窝权限检测，在第一次初始化CTCellularData的时候，如果直接快速调用，返回值可能是.unknown而判定错误的问题
 1.8.3 | 修复macOS的编译问题，新增macOS的Demo
 1.8.2 | 删除了一个评论，规避TC合规问题
 1.8.1 | 修复了使用Xcode 12.1编译时，由于苹果的Bug导致iOS 14.0版本上对应的API符号产生Crash的问题
 1.8.0 | 新增对5G蜂窝制式的相关接口，返回值等状态，在iPhone 12系列设备上有效
 1.7.2 | 修复小概率蜂窝权限判定出错的情况，利用苹果系统API做双重保底
 1.7.1 | 修复如果使用方从+load方法中调用蜂窝相关接口时，会造成方法返回值错误的问题，且对应方法必须等用户第一次网络状态变化（切WiFi/蜂窝）后才可恢复正常
 1.7.0 | 添加便携方法，迁移TTBaseLib和其他SDK提供的上报用的Connection Method Name，支持macOS和tvOS，对应蜂窝方法会禁用掉
 1.6.1 | 修复了蜂窝权限校验，在后台切换前台后，iOS 13+上，如果用户不手动切换WiFi/蜂窝状态，会导致永远返回undetermined
 1.6.0 | 添加了用于获取IP地址/域名的相关工具接口，用于一些常见业务的平滑迁移
 1.5.1 | 修复了currentReachabilityStatus小概率的多线程不安全问题，Status Cache功能使用线程安全的方式重新实现
 1.5.0 | TTReachability性能改进，现在reachabilityForInternetConnection返回单例而不是一个新实例，避免调用方注册不同实例多次
 1.4.0 | 提供了host，IP的公开接口，能够用来，在TTReachabilityChanged通知到来时，筛选和过滤指定需要的TTReachability对象，避免频繁回调
 1.3.2 | 修复了currentPrioritizedCellularProviders方法实现，如SIM卡在当地不可用时依然能拿到CTCarrier；修复了如果使用者在+load方法中调用方法，会拿不到SIM卡信息的问题
 1.3.1 | 修复了currentPrioritizedCellularProviders在双卡设备上，可能有小概率的Crash的问题 
 1.3.0 | 支持了获取CTRadioAccessTechnology的相关API
 1.2.1 | 尝试通过减少对CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology访问频率，直接读取上一次变化后的值，来减少Crash概率
 1.2.0 | 增加了一个便携方法，可以拿到单双卡的CTCarrier按照优先级排列的数组，可以用于一些通用上报场景
 1.1.2 | 修复了蜂窝变化通知时直接访问属性，导致小概率多线程Crash的问题，改为全部到主线程中处理
 1.1.1  | 修复了仅在iOS 12.0版本上设备蜂窝运营商返回nil的问题，兼容苹果的Bug
 1.1.0  | 增加了能够拿到当前用户配置的流量卡，对应的CTCarrier的接口，目前只能在iOS 13上有效
 1.0.3  | 修复由于在initialize方法中异步初始化，可能导致使用方第一次调用is4GConnected系列方法返回错误值的问题
 1.0.2  | 再次修复蜂窝网络权限判定偶尔在切换时误判的问题
 1.0.1  | 修复蜂窝网络权限检测的功能，在iPhone通过WiFi从关闭切换到打开，在这个切换的2秒内会误判成`WLANAndCellularNotPermitted`的问题
 1.0.0  | 删除已经被Deprecated的符号`kTTNetworkAuthorizationStatus`，修复和公网库Reachability的符号`kReachabilityChangedNotification`冲突
 0.11.1  | 同1.6.1改动（0.x版本兼容）
 0.11.0  | 同1.6.0改动（0.x版本兼容）
 0.10.0  | 同1.5.0改动（0.x版本兼容）
 0.9.0  | 同1.4.0改动（0.x版本兼容）
 0.8.2  | 同1.3.2改动（0.x版本兼容）
 0.8.1  | 同1.3.1改动（0.x版本兼容）
 0.8.0  | 同1.3.0改动（0.x版本兼容）
 0.7.1  | 同1.2.1改动（0.x版本兼容）
 0.7.0  | 同1.2.0改动（0.x版本兼容）
 0.6.2  | 同1.1.2改动（0.x版本兼容）
 0.6.1  | 同1.1.1改动（0.x版本兼容）
 0.6.0  | 同1.1.0改动（0.x版本兼容）
 0.5.4  | 同1.0.3改动（0.x版本兼容）
 0.5.3  | 添加一个通知同名符号·TTReachabilityChangedNotification·，以解决下游库同时和1.0版本的兼容问题
 0.5.2  | 同1.0.2改动（0.x版本兼容）
 0.5.1  | 同1.0.1改动（0.x版本兼容）
 0.5.0  | 新增用于获取指定SIM卡的CTCarrier的接口，用于上层调用方拿到运营商相关信息
 0.4.0  | 优化Swift对应的导出API，使用标准的Enum枚举命名方式，Deprecated了旧的`kTTNetworkAuthorizationStatus`枚举
 0.3.0  | 添加能直接获取蜂窝状态的便捷接口，不需要依次调用is4GConnected系列方法
 0.2.2  | 临时修复仅在iOS 12.0.0-Beta版本上，由于苹果SDK未包含对应的符号，导致运行时Crash的问题
 0.2.1  | 修复在iOS 12上，多线程访问CTTelephonyNetworkInfo的相关属性由于线程不安全导致Crash的问题
 0.2.0  | 蜂窝数据检测的所有方法更新，支持获取双卡对应的配置，支持检测当前可用SIM卡列表
 0.1.16 | 删除所有Dependency，缓存间隔由外部配置；API添加Nullability标识
 0.1.15 | 修复缓存时间阈值单位为秒而不是毫秒
 0.1.14 | 对Reachability的频控和缓存机制优化，引入Kitchen开关
 0.1.13 | 修改Framework引入方式
 0.1.12 | 删除对缓存的开关
 0.1.11 | 删除无用文件
 0.1.10 | Rollback 回 0.1.8 版本的组织，去除 NetworkUtilities 和 TTNetworkHelper
 0.1.9 | 加入 NetworkUtilities 和 TTNetworkHelper
 0.1.8 | 更换网络判断的优化开关key的内容
 0.1.7 | 增加对 App 无网络权限的判断接口
 0.1.6 | 优化对 CTRadioAccessTechnologyDidChangeNotification 的处理 
 0.1.5 | 解决 CTTelephonyNetworkInfo 在非主线程初始化时可能产生死锁的问题
 0.1.4 | TTReachability 增加网络状态变化通知的滤重策略
 0.1.3 | 性能优化，针对 SCNetworkReachabilityGetFlags() 可能耗时较长的问题，增加了一个可以快速判断网络是否连通的方法，并用开关控制 
 0.1.2 | 增加一个新的方法判断网络是否联通 

## 库维护文档

[TTReachability库文档](https://docs.bytedance.net/doc/5INJF94VRlMnXy0spBoW9a)

## 组件交流反馈群

[点击加入Lark反馈群](https://applink.feishu.cn/client/chat/open?chatId=6649923848676311310)

## 作者

lizhuoli@bytedance.com
caitengyuan@bytedance.com

## 许可证

MIT

