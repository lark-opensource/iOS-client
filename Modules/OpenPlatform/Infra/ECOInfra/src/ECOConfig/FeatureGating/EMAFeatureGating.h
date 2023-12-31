//
//  EMAFeatureGating.h
//  ECOInfra
//
//  Created by Meng on 2021/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 小程序引擎相关的feature gating keys
@interface EMAFeatureGating : NSObject

/**
 获取feature gating配置

 @param key feature gating key
 @return 开关是否打开
 */
+ (BOOL)boolValueForKey:(NSString *)key;

/**
 获取feature gating配置

 @param key feature gating key
 @param defaultValue 未获取到配置时的默认值
 @return 开关是否打开
 */
+ (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue;

/**
 主动获取对应key的线上配置

 @param key key
 @param completion completion
 */
+ (void)checkForKey:(NSString *)key completion:(void (^)(BOOL enable))completion;

/// 获取静态 FG Value，幂等
/// @param key feature gating key
+ (BOOL)staticBoolValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
