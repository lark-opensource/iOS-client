//
//  EMALibVersionManager.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/4/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMALibVersionManager : NSObject

/// 开始更新小程序JSSDK基础库（如果有必要）
- (void)updateLibIfNeed;
//根据外部传入的JSSDK，判断是否需要更新最新版的JSSDK
- (void)updateLibIfNeedWithConfig:(NSDictionary *)config;
/// 开始更新block js sdk（如果有必要）
- (void)updateBlockLibIfNeed;

/// 开始更新消息卡片 js sdk（如果有必要）
- (BOOL)updateCardMsgLibIfNeedWithComplete:(void (^)(NSString *__nullable errorMsg, BOOL success))complete;

/// 开始预加载基础库（如果有必要）
- (void)preloadLibIfNeed;

/// 调用preloadLibIfNeed 方法时，判断是否需要更新预加载来源
/// 由于preloadLibIfNeed 方法中有setting：kBDPSJSLibPreloadOptmizeTma开关，更新前需要先check
/// updateLibComplete 中逻辑不需要，已校验setting 开关
/// @param preloadFrom 预加载来源
+ (void)updatePreloadForPreloadLibIfNeed:(NSString * _Nonnull)preloadFrom;

//检查小程序JSSDK，如果沙箱缓存的版本小于飞书当前版本，则清空沙箱的JSSDK
+ (void)checkJSSDKCacheAndCleanIfNeeded;
@end

NS_ASSUME_NONNULL_END
