//
//  CJPayBizParam.h
//  CJPay
//
//  Created by 王新华 on 2019/5/5.
//

#import <Foundation/Foundation.h>
#import "CJPayCookieUtil.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayAppInfoConfig.h"
#import "CJPayTracker.h"
#import "CJPayLocalizedPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBizParam : NSObject

+ (instancetype)shared;

@property (nonatomic, copy) NSString *appName;
// 配置支付收银台首页title， 使用CJPayManager进行配置
//@property (nonatomic, strong) CJPayNameModel *nameModel;

// 域名配置，如果不设置会使用默认域名
@property (nonatomic, copy) NSString *configHost;

// 风控参数
@property (nonatomic, copy, readonly) CJPayConfigBlock riskInfoBlock;

/**
 设置SDK要显示的语言
 @param language 要设置的语言参数
 */
- (void)setupLanguage:(CJPayLocalizationLanguage)language;

/**
 根据业务方需要设置风控参数 //风控字段，需要接入方把aid，did，iid传进来
 */
- (void)setupRiskInfoBlock:(CJPayConfigBlock)riskInfoBlock;

/**
 配置WebView请求中的cookie参数，主要用于SDK登录态同步 [在登录态发生变化时，请重新调用改方法设置参数]
 
 @param cookieBlock 返回需要配置的Cookie信息的block [清空登录信息cookie是，可以返回@{@"key": @""}，如果返回nil的话，SDK不会做cookie清空的操作]
 */
- (void)setupCookieWith:(nullable CJPayConfigBlock)cookieBlock;
// app退出登录时清空cookie
- (void)cleanCookies DEPRECATED_ATTRIBUTE;

/**
 配置回调。

 @param trackerDelegate 实现`CJPayManagerBizDelegate`的类实例
 */
- (void)setupTrackerDelegate:(id<CJPayManagerBizDelegate>) trackerDelegate;

/**
 配置宿主app的一些基本信息
 @param appInfoConfig 宿主app基本信息的model
 **/
- (void)setupAppInfoConfig:(CJPayAppInfoConfig *)appInfoConfig;

@end

NS_ASSUME_NONNULL_END
