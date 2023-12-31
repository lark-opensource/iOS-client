//
//  TouTiaoPushSDK.h
//  TouTiaoPushSDKDemo
//
//  Created by wangdi on 2017/7/30.
//  Copyright © 2017年 wangdi. All rights reserved.
//

#import <UIKit/UIKit.h>

//使用时请结合wiki进行集成 地址 https://wiki.bytedance.net/pages/viewpage.action?pageId=93948218

@interface TTBaseRequestParam : NSObject
/**
 appID 如果不传，默认为 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SSAppID"]
 */
@property (nonatomic, copy) NSString *aId;
/**
 设备ID 如果不传，默认会从 TTInstallIDManager 中读取
 */
@property (nonatomic, copy) NSString *deviceId;
/**
 安装ID 如果不传，默认会从 TTInstallIDManager 中读取
 */
@property (nonatomic, copy) NSString *installId;
/**
 app名字， 如果不传，默认 为 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AppName"]
 */
@property (nonatomic, copy) NSString *appName;

/**
 请求的域名，为了实现动态选路,不传默认为http://ib.snssdk.com
 */
@property (nonatomic, copy) NSString *host;

/**
  lark 根据帐号、设备等维度维护的设备登录信息的ID
  https://bytedance.feishu.cn/docs/doccn8uhGoyT2AMiOS9bsSOylxf#
*/
@property (nonatomic, copy) NSString* deviceLoginId;

/**
 初始化方法

 @return 对象本身
 */
+ (instancetype)requestParam;

@end

@interface TTChannelRequestParam : TTBaseRequestParam
/**
 渠道，如local_test,如果不传，默认为 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"]
 */
@property (nonatomic, copy) NSString *channel;
/**
 iOS这边默认传[13],非必传
 */
@property (nonatomic, copy) NSString *pushSDK;
/**
 app版本号,如果不传，默认为 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
 */
@property (nonatomic, copy) NSString *versionCode;
/**
 系统版本号，非必传，默认为 [[UIDevice currentDevice] systemVersion]
 */
@property (nonatomic, copy) NSString *osVersion;
/**
 bundleID 如果不传,默认为 [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]
 */
@property (nonatomic, copy) NSString *package;
/**
 应用内推送开关状态，0：打开，1:关闭  必传
 */
@property (nonatomic, copy) NSString *notice;

/**
 系统类型，默认为iOS 非必传
 */
@property (nonatomic, copy) NSString *os;

@end

@interface TTUploadTokenRequestParam : TTBaseRequestParam
/**
 device_token 必传
 */
@property (nonatomic, copy) NSString *token;

@end

@interface TTUploadSwitchRequestParam : TTBaseRequestParam

/**
 应用内推送开关状态，0：打开，1:关闭  必传
 */
@property (nonatomic, copy) NSString *notice;

@end

@interface TTBaseResponse : NSObject

/**
 请求的错误信息
 */
@property (nonatomic, strong) NSError *error;

/**
 请求的返回结果,里面有一个message 字段,该字段为success表示成功，否则就是请求失败
 */
@property (nonatomic, strong) id jsonObj;

/**
 请求是否成功,成功为YES,失败为NO，可以用这一个字段来判断成功还是失败
 */
@property (nonatomic, assign) BOOL success;

@end

@interface TouTiaoPushSDK : NSObject
/**
 发出一个相应的请求

 @param requestParam 请求参数的模型，用于封装参数，传不同的模型会对应不同的请求，TTChannelRequestParam是上报device_id的请求;TTUploadTokenRequestParam是上报token的请求;TTUploadSwitchRequestParam是上报推送开关的请求
 @param completionHandler 请求结果的回调
 */
+ (void)sendRequestWithParam:(TTBaseRequestParam *)requestParam completionHandler:(void (^)(TTBaseResponse *response))completionHandler;

/**
 推送的打点封装到SDK中

 @param ruleId iOS是payload中的rid字段
 @param clickPosition 应用外点击用notify，应用内点击用alert
 @param postBack payload中的post_back字段的值
 */
+ (void)trackerWithRuleId:(NSString *)ruleId clickPosition:(NSString *)clickPosition postBack:(NSString *)postBack;

@end
