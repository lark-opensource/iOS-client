//
//  EMAAppUpdateManagerV2.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import <Foundation/Foundation.h>
#import "EMAAppUpdateInfoManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 小程序更新策略第二版，策略稳定后移除旧策略
 */
@interface EMAAppUpdateManagerV2 : NSObject

@property (nonatomic, strong, nonnull, readonly) EMAAppUpdateInfoManager *infoManager;            // 更新信息管理器，负责信息管理和持久化
@property (nonatomic, strong, nonnull, readonly) dispatch_queue_t updateSerialQueue;               // 更新代码执行队列，所有的更新逻辑代码都在这个串行队列执行，保证线程安全

/**
 *  收到小程序更新的Push
 *  启动时离线Push时机可能早于引擎初始化，在引擎初始化之前收到的Push将会被缓存
 *  @param appID 小程序appid
 *  @param latency 请求最长延迟时间 单位：秒
 */
- (void)onReceiveUpdatePushForAppID:(NSString *)appID
                            latency:(NSInteger)latency
                          extraInfo:(NSString *)extraJson;



/// 是否可以在4G（非Wi-Fi下下载）
/// @param appID appid
+ (BOOL)canCellularDownloadFor:(NSString *)appID;

//测试方法
//+ (void)simulatePushForApp:(NSString *)appID andVersion:(NSString *)version;

@end

NS_ASSUME_NONNULL_END
