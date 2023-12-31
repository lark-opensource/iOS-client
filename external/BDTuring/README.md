# BDTuring

验证码SDK 重构版。

[集成文档](https://bytedance.feishu.cn/space/doc/doccnklmrJQuehgpDbJAAex4Deh#)

# 要求

- iOS 8.0+
- Xcode 9.0+

# 接入方式

```
pod 'BDTuring'
```
# 运行Example工程

+ clone工程
+ `pod install`
+ `xed .`


# 文档

[验证码SDK文档汇总](https://bytedance.feishu.cn/space/doc/doccnRNu5FqOqwchONDgBE5d0uc)


# API 说明

## 初始化SDK

```Objective-C
#import <BDTuring/BDTuring.h>
#import <BDTuring/BDTuringConfig.h>

- (void)startTuringSDK {
    BDTuringConfig *config = [BDTuringConfig new];
    config.appID = "1234";
    config.channel = @"App Store";
    ...
    config.delegate = self;

    BDTuring *turing = [[BDTuring alloc] initWithConfig:config];
    ...
}

```

## 呼起图片验证码

```
#import <BDTuring/BDTuring.h>
#import <BDTuring/BDTuringConfig.h>

BDTuringVerifyCallback callback =^(BDTuringVerifyStatus status, NSString *token, NSString *mobile) {
    NSLog(@"callback status(%zd)", status);
};

[turing popPictureVerifyViewWithRegionType:BDTuringRegionTypeCN
                   presentingView:nil
                        challengeCode:1104
                         callback:callback];
```
## 呼起短信验证码

```
#import <BDTuring/BDTuring.h>
#import <BDTuring/BDTuringConfig.h>

BDTuringVerifyCallback callback =^(BDTuringVerifyStatus status, NSString *token, NSString *mobile) {
    NSLog(@"callback status(%zd)", status);
};

[turing popSMSVerifyViewWithRegionType:BDTuringRegionTypeCN
                   presentingView:nil
                        scene:1104
                         callback:callback];
```

## 关闭验证码

```
#import <BDTuring/BDTuring.h>
#import <BDTuring/BDTuringConfig.h>

[turing closeVerifyView];

```

## 组件交流反馈群(必选)

[点击加入Lark反馈群](lark://client/chatchatId=6774216994444017928)
