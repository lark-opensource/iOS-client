//
//  CJPayDebugManager.h
//  CJPay
//
//  Created by wangxiaohong on 2020/1/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDebugManager : NSObject

/**
* 打开boe环境，这里会自动更新cookies
*/

+ (void)enableBoe;

/**
* 关闭boe环境
*/
+ (void)disableBoe;


+ (BOOL)boeIsOpen;

/**
* 设置聚合boe/线上域名, 默认为 https://pay-boe.snssdk.com
*/
+ (void)setupConfigHost:(NSString *)configHost;

/**
*切换三方boe/线上域名，默认为  http://bytepay-boe.byted.org
*/
+ (void)setupBDConfigHost:(NSString *)configHost;
 
/**
* 设置boe后缀, 默认为.boe-gateway.byted.org
*/
+ (void)setupBoeSuffix:(NSString *)boeSuffix;
+ (NSString *)boeSuffix;

/**
* 设置boe环境url白名单，默认为 @[@"https://tp-pay-test.snssdk.com", @"https://tp-pay.snssdk.com"]
*/
+ (void)setupBoeUrlWhiteList:(NSArray *)boeWhiteList;
+ (NSArray *)boeUrlWhiteList;

/**
* 设置boe环境的参数,updateBoeCookies方法会使用这里设置的参数更新cookie，默认为 @{@"x-tt-env" : @"prod"}
*/
+ (void)setupBoeEnvDictionary:(NSDictionary *)boeEnvDictionary;
+ (NSDictionary *)boeEnvDictionary;

/**
* 更新boe环境的cookies
*/
+ (void)updateBoeCookies;


/// 设置boe环境到request的header内
/// @param request 请求对象
+ (void)p_setBOEHeader:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
