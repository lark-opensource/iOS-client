# DouyinOpenPlatformSDK

[TOC]

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

DouyinOpenPlatformSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DouyinOpenPlatformSDK'
```

## 授权

```objc

DouyinOpenSDKAuthRequest *request = [[DouyinOpenSDKAuthRequest alloc] init];

request.permissions = [NSOrderedSet orderedSetWithObject:@"user_info"];

request.additionalPermissions = [NSOrderedSet orderedSetWithObjects:
@{ @"permission" : @"mobile", @"defaultChecked" : @"0" },
nil];

[request sendAuthRequestViewController:self completeBlock:^(BDOpenPlatformAuthResponse * _Nonnull resp) {
        __strong typeof(ws) sf = ws;
        NSString *alertString = nil;
 if (resp.errCode == 0) {
            alertString = [NSString stringWithFormat:@"Author Success Code : %@, permission : %@",resp.code, resp.grantedPermissions];
        } else{
            alertString = [NSString stringWithFormat:@"Author failed code : %@, msg : %@",@(resp.errCode), resp.errString];
        }
        [UIAlertController showMsg:alertString inVC:sf];
    }];

```
### 实名授权

```objc

BDOpenPlatformAuthRequest *request = [[BDOpenPlatformAuthRequest alloc] initWithAppType:self.appType];
request.permissions = [NSOrderedSet orderedSetWithObject:@"user_info"];

request.extraInfo = @{
        @"skip_tel_num_bind":@(self.dataControl.skipMobileBind),
        @"certificationInfo" : @{ @"verify_scope" : @"certification.two_element,certification.face",
                                  @"verify_tic" : @"xxx"
        }
    };

```

## 分享

### 分享到IM

```objc
DouyinOpenSDKShareRequest *request = [[DouyinOpenSDKShareRequest alloc] init];

request.localIdentifiers = media;//NSArray<NSString *> *

request.shareAction = BDOpenPlatformShareTypeShareContentToIM;

```

```objc
DouyinOpenSDKShareRequest *request = [[DouyinOpenSDKShareRequest alloc] init];

BDOpenPlatformShareLink *link = [BDOpenPlatformShareLink new];
link.linkURLString = @"https://developer.open-douyin.com/";
link.linkTitle = @"抖音开放平台";
link.linkDescription = @"抖音开放平台，致力于打造抖音开放的生态系统，将从基础能力、内容、数据、服务等层面的开放，为开发者提供高效便捷的解决方案";
link.linkCoverURLString = @"https://sf3-ttcdn-tos.pstatp.com/obj/ttfe/open/imgs/logo-text.png";

request.shareLink = link;

request.shareAction = BDOpenPlatformShareTypeShareContentToIM;

```

### 自定义渠道分享

```objc
#import "DouyinOpenSDKShare+Inner.h"

@interface DouyinOpenSDKShareRequest (Inner)

@property (nonatomic, copy) NSDictionary *customPlatformInfo;

@end

request.customPlatformInfo = @{ @"shareUrl" : @"", "consumerAppId" : @"" };

```

### 自定义授权的Client Key

```objc
#import "DouyinOpenSDKAuth+Inner.h"

@interface DouyinOpenSDKAuthRequest (Inner)

@property (nonatomic, copy) NSDictionary *customPlatformInfo;

@end

request.customPlatformInfo = @{ @"appBundleId" : @"", "consumerAppId" : @"" };

```

这个自定义的consumerAppId也需要在plist里面注册。

## ClientTicket

* 引入 subspec `Ticket`

```
示例：
pod 'DouyinOpenPlatformSDK', :subspecs => ['Auth', 'Share', 'Ticket']
```

* 引入头文件

```
#import <DouyinOpenSDK/DYOpenTicketService.h>
```

* 注册

    > 获取 clientCode 需要自己后台包装接口提供给客户端。因为接口需要用到 client_secret，客户端内置 client_secret 会有泄露风险，所以最好是自己后台封装 api 进行调用。

    接口：
    
    ```
    /// 注册获取 client code 的请求回调，业务在 block 里自行发起请求
    /// ！！！注意最后需要调用 finishRequestBlock 通知 openSDK 结果 ！！！
    /// ！！！注意最后需要调用 finishRequestBlock 通知 openSDK 结果 ！！！
    /// ！！！注意最后需要调用 finishRequestBlock 通知 openSDK 结果 ！！！
    /// @param clientKey 开放平台上申请的应用 key
    /// @param requestBlock 获取 clientCode 的网络请求操作，一般是由开发者客户端调用开发者服务端封装好的接口（为了安全，客户端不要本地内置 clientSecrect）
    - (void)registerClientKey:(NSString *)clientKey requestClientCodeBlock:(nonnull DYOpenRequestClientCodeBlock)requestBlock;
    ```
    
    示例：
    
    ```
    [[DYOpenTicketService sharedInstance] registerClientKey:[self getClientKey] requestClientCodeBlock:^(NSString * _Nonnull clientKey, DYOpenFinishRequestClientCodeBlock  _Nonnull finishRequestBlock) {
        [DemoNetworkManager requestClientCodeWithCompletion:^(NSString * _Nullable clientCode, NSError * _Nullable error) {
            if (error) {
                NSString *message = [NSString stringWithFormat:@"errCode: %ld\n\nerrMsg: %@", error.code, error.localizedDescription];
                [UIAlertController showTitle:@"fetch clientCode error" msg:message inVC:[UIApplication sharedApplication].keyWindow.rootViewController];
                return;
            }
            finishRequestBlock(clientCode, error); // 注意得到 client code 后，这里一定要回调一下通知 OpenSDK
        }];
    }];
    ```

* 调用 OpenAPI

    接口：
    
    ```
    /// 使用 client ticket 发送 GET 请求开放平台接口
    /// @param domainAndPath 包含 domain + path
    /// @param extraReqBlock 可以设置 req header 等参数
    /// @param complete 请求回调
    - (void)requestGETOpenAPIWithDomainAndPath:(NSString *_Nonnull)domainAndPath
                                 extraReqBlock:(DYOpenOpenAPIExtraReqBlock _Nullable)extraReqBlock
                                      complete:(DYOpenOpenAPICompleteBlock _Nullable)complete;
    
    /// 使用 client ticket 发送 POST 请求开放平台接口
    /// @param domainAndPath 包含 domain + path
    /// @param contentType form 或 json 等
    /// @param bodyDict body 参数
    /// @param extraReqBlock 可以设置 req header 等参数
    /// @param complete 请求回调
    - (void)requestPOSTOpenAPIWithDomainAndPath:(NSString *_Nonnull)domainAndPath
                                    contentType:(DYOpenNetworkContentType)contentType
                                       bodyDict:(NSDictionary *_Nullable)bodyDict
                                  extraReqBlock:(DYOpenOpenAPIExtraReqBlock _Nullable)extraReqBlock
                                       complete:(DYOpenOpenAPICompleteBlock _Nullable)complete;
    ```

    示例：  
    
    ```
    NSString *baseURLString = @""; // 自行填入实际请求 url
    [[DYOpenTicketService sharedInstance] requestGETOpenAPIWithDomainAndPath:baseURLString extraReqBlock:^(NSMutableURLRequest * _Nonnull request, NSString * _Nullable clientTicket) {
        // 按需填写 header 等，如：
        // [request setValue:clientTicket forHTTPHeaderField:@"access-token"];
    } complete:^(NSDictionary * _Nullable respDict, NSDictionary * _Nullable respHeaderDict, NSError * _Nullable error) {
    }];
    ```

## Author

guoqiang.qian@bytedance.com

## License

DouyinOpenPlatformSDK is available under the MIT license. See the LICENSE file for more info.
