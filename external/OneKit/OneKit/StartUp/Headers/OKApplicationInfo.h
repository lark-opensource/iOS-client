//
//  OKApplicationInfo.h
//  OKStartUp
//
//  Created by bob on 2020/1/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Config自定义配置参考如下，需要在OKAppCustomConfigFunction中
/// 仅做简单配置，请勿进行耗时操作

/**
#import <OneKit/OKStartUpGaia.h>
#import <OneKit/OKStartUpFunction.h>
 
OKAppCustomConfigFunction() {
    [OKApplicationInfo sharedInstance].xx = xxx;
 }
 */

/// 存储应用信息
/// 默认值从bundle或onekit-config.plist中读取
@interface OKApplicationInfo : NSObject

/* 默认值从onekit-config.plist中读取 */
@property (nonatomic) NSString *appID;
@property (nonatomic) NSString *accessKey;  // mars_access_key
@property (nonatomic) NSString *secretKey;  // mars_secret_key
@property (nonatomic, nullable) NSDictionary *serviceInfo;

/* 默认值从bundle中读取 */
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appDisplayName;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *buildVersion;
@property (nonatomic, copy) NSString *buildVersionCode;
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, assign) BOOL isInhouseApp;
@property (nonatomic, assign) BOOL isI18NApp;

@property (nonatomic, copy) NSString *deviceModel;/// return string like "iPhone9,1"
@property (nonatomic, copy) NSString *devicePlatform;/// return "iPod", "iPad" or "iPhone"
@property (nonatomic, copy) NSString *systemVersion;
@property (nonatomic, copy, nullable) NSString *sharingKeyChainGroup;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
