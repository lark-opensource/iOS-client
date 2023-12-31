//
//  EMAAppUpdateManager.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/6/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAAppUpdateManager : NSObject

+ (instancetype)sharedInstance;

/**
 *  收到小程序更新的Push
 *  启动时离线Push时机可能早于引擎初始化，在引擎初始化之前收到的Push将会被缓存
 *  @param appID 小程序appid
 *  @param latency 请求最长延迟时间 单位：秒
 */
- (void)onReceiveUpdatePushForAppID:(NSString *)appID
                            latency:(NSInteger)latency
                          extraInfo:(NSString *)extraJson;

/**
 *  检查是否有缓存的Push并且处理
 */
- (void)checkCachedPush;


/// 收到产品化止血的push
/// @param appID 需要止血的应用ID
/// @param extra 保留字段
- (void)onReceiveSilenceUpdateAppID:(NSString *)appID extra:(NSString *)extra;

//测试方法
//+ (void)simulatePushForApp:(NSString *)appID andVersion:(NSString *)version;

@end

NS_ASSUME_NONNULL_END
