# AWECloudCommand

[![CI Status](http://img.shields.io/travis/Fang Wei/AWECloudCommand.svg?style=flat)](https://travis-ci.org/Fang Wei/AWECloudCommand)
[![Version](https://img.shields.io/cocoapods/v/AWECloudCommand.svg?style=flat)](http://cocoapods.org/pods/AWECloudCommand)
[![License](https://img.shields.io/cocoapods/l/AWECloudCommand.svg?style=flat)](http://cocoapods.org/pods/AWECloudCommand)
[![Platform](https://img.shields.io/cocoapods/p/AWECloudCommand.svg?style=flat)](http://cocoapods.org/pods/AWECloudCommand)

## 简介
`AWECloudCommand`是一种用于在线日志回捞，定点对特定设备执行操作的解决方案。支持如下功能:

* 日志回捞
* 磁盘目录大小回捞
* 性能信息实时回捞(cpu，内存等)
* 网络连通性检测
* 自定义命令
* Alog (须接入APM@丰亚东)

## 环境依赖
* Xcode 7.0以上
* iOS 8.0以上

## 第三方库依赖
* SSZipArchive

## 示例
编译示例工程

1. clone仓库

```
git clone git@code.byted.org:ugc/AWECloudCommand.git
```

2. 运行`pod install`

```
cd to/AWECloudCommand/Example

pod install
```

## 客户端接入
### 集成`AWECloudCommand`
```source

source 'git@code.byted.org:iOS_Library/privatethird_source_repo.git'

```

```ruby

pod 'AWECloudCommand', '1.0.0'

```

### 基本设置
根据项目需要选择合适时机来初始化：

```objective-c
// 云控查询、上传接口所需要的参数
[[AWECloudCommandManager sharedInstance] setCloudCommandParamModelBlock:^AWECloudCommandParamModel * _Nonnull{
    AWECloudCommandParamModel *paramModel = [[AWECloudCommandParamModel alloc] init];
    paramModel.appID = [UIApplication btd_appID];    // 必填, 产品ID
    paramModel.deviceId = GET_SERVICE(InstallAndDeviceIDService).deviceID;    // 必填, 设备ID
    paramModel.userId = GET_SERVICE(AWEUserService).currentLoginUser.userID;    // 选填, 用户ID
    paramModel.appBuildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];    // 选填，客户端版本(默认取CFBundleVersion)
    return paramModel;
}];

// 公共参数，可不填
[[AWECloudCommandManager sharedInstance] setCommonParamsBlock:^NSDictionary * _Nonnull{
    return [AWENetworkUtil commonParameters];
}];
```

### 使用`AWECloudCommand`

根据项目需要，选择合适的时机拉取命令

```objective-c
[[AWECloudCommandManager sharedInstance] getCloudControlCommandData];
```

### 自定义网络请求

云控默认使用苹果提供的网络库进行网络请求，如需使用其他网络库(如TTNetwork)。云控提供了自定义网络请求代理的方法。设置方法如下:

```objective-c
    // AWECloudCommandNetworkDelegate 为实现了AWECloudCommandNetworkDelegate协议的对象
    [[AWECloudCommandManager sharedInstance] setNetworkDelegate:[[AWECloudCommandNetworkDelgateImpl alloc] init]];
```

### 自定义Host
云控默认的host地址是mon.snssdk.com, 然在一部分国家和地区需要根据部署的服务器地点切换成其他地址, 设置方法如下:

```
if (IsDouYin()) {
    [AWECloudCommandManager sharedInstance].host = @"mon.snssdk.com";    // 国内
} else if (IsTikTok()) {
    [AWECloudCommandManager sharedInstance].host = @"mon.byteoversea.com";    // 新加坡
} else if (IsMusically()) {
    [AWECloudCommandManager sharedInstance].host = @"i.isnssdk.com";    // 美东
}
```

### 配置长链接
在网页上下发命令以后, 如果需要在线的设备能够立即执行操作, 需要配置长链接服务。

云控默认的长链接service为1004, 将payload信息传给AWECloudManager, 即可执行任务。

```
    [[AWECloudCommandManager sharedInstance] executeCommandWithData:msg.payload];
```

### 自定义命令

除了默认的命令外, 云控还可以根据业务需要, 自定义命令, 在接收到云控指令后执行操作。

首先自定义一个指令的接受类，实现AWECloudCommandManager.h文件中声明的AWECustomCommandHandler协议，如定义一个切换CDN的命令： 

``` objective-c
@implementation AWELiveCustomCloudCommandSwitchCDN

+ (NSString *)cloudCommandIdentifier
{
    return @"switch_cdn";
}

+ (instancetype)createInstance
{
    return [[[self class] alloc] init];
}

- (void)excuteCommandWithParams:(nonnull NSDictionary *)params completion:(nonnull AWECustomCommandCompletion)completion
{
    if ([GET_PROTOCOL(AWELiveModuleService) hasCreatedLiveRoom]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AWECloudCommandLiveSwitchCDNNotification object:nil userInfo:@{@"command": [^(NSString *logString) {
            NSData *data = [logString dataUsingEncoding:NSUTF8StringEncoding];
            
            AWECustomCommandResult *result = [[AWECustomCommandResult alloc] init];
            result.data = data;
            result.fileType = @"text";
            result.error = nil;
            AWEBLOCK_INVOKE(completion, result);
        } copy]}];
    } else {
        NSString *logString = @"No created live room.";
        NSData *data = [logString dataUsingEncoding:NSUTF8StringEncoding];
        
        AWECustomCommandResult *result = [[AWECustomCommandResult alloc] init];
        result.data = data;
        result.fileType = @"text";
        result.error = nil;
        AWEBLOCK_INVOKE(completion, result);
    }
}

@end
```

然后调用AWECloudCommandManager类中的接口将自定义指令类注册进去，形如：

```
[[AWECloudCommandManager sharedInstance] addCustomCommandHandlerClsArray:@[[AWELiveCustomCloudCommandSwitchCDN class]];
```

编译上线后, 可在后台配置"自定义模板", 格式如下:

```json
{
    "command": "switch_cdn"
}
```

> 注意: 自定义模版中定义的JSON格式的参数与excuteCommandWithParams:completion:传入的字典完全一致。参数至少要包含一个command字段, 里面的内容需要cloudCommandIdentifier返回的key完全一致。

## Slardar平台接入 & 命令下发
请参照[云控功能集成指南](https://slardar.bytedance.net/help/ios/cloud_command.html#云控简介)

@fengyadong

## 作者 
* Fang Wei, fangwei.02@bytedance.com
* Shuo Shan, shanshuo@bytedance.com

## License
AWECloudCommand is available under the MIT license. See the LICENSE file for more info.