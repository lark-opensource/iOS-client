//
//  BDPSettingsManager.h
//  Timor
//
//  Created by 张朝杰 on 2019/7/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// (小程序 SDK Settings 食用指北（iOS版）)[https://bytedance.feishu.cn/space/doc/doccnTdqakOj7x3Yddm0BUBqmNb#]

typedef NSString BDPSettingsKey;

typedef void (^BDPSettingsUpdateHandler)(NSDictionary *config);

@interface BDPSettingsManager : NSObject

+ (instancetype)sharedManager;

/**
 @brief 注册本地Settings默认值，优先级别：远程 > 本地缓存 > 默认值
 @param defaultSettings 默认Settings字典
 */
- (void)registerSettings:(NSDictionary <BDPSettingsKey *, id>*)defaultSettings;

/// 监听settings某个配置项的更新(不为nil, 说明增量有更新, 就会触发回调)
/// @param configName 配置项名称, 非配置项下的返回值名称
/// @param handler 回调handler, 参数返回该配置项下对应的原始字典. 触发线程非主线程!!!
- (void)observeUpdateForConfigName:(NSString *)configName withHandler:(BDPSettingsUpdateHandler)handler;

/**
 @brief 新增本地Settings值，新值会覆盖已有值
 @param defaultSettings 默认Settings字典
 */
- (void)addSettings:(NSDictionary *)defaultSettings;

/**
 @brief 从服务端获取Settings，获取成功不再请求
 @param completion 获取结果，即使error不为nil，依旧能获取到兜底Settings
 */
- (void)updateSettingsIfNeed:(nullable void (^)(NSError *))completion;

/**
 @brief 从服务端获取Settings，强制重新请求
 @param completion 获取结果，即使error不为nil，依旧能获取到兜底Settings
 */
- (void)updateSettingsByForce:(nullable void (^)(NSError *))completion;

/**
 @brief 清除本地Settings缓存，调试使用
 */
+ (void)clearCache;

/// 添加监听者，用于每次应用回到前台更新基础库
- (void)setupObserver;

/**
 @brief 获取布尔型值配置，默认NO
 @param key key
 */
- (BOOL)s_boolValueForKey:(BDPSettingsKey *)key;
/**
 @brief 获取整型值配置，默认0
 @param key key
 */
- (NSInteger)s_integerValueForKey:(BDPSettingsKey *)key;
/**
 @brief 获取浮点型值配置，默认0
 @param key key
 */
- (CGFloat)s_floatValueForKey:(BDPSettingsKey *)key;
/**
 @brief 获取字符串型值配置，默认nil
 @param key key
 */
- (NSString *)s_stringValueForKey:(BDPSettingsKey *)key;
/**
 @brief 获取数型组值配置，默认nil
 @param key key
 */
- (NSArray *)s_arrayValueForKey:(BDPSettingsKey *)key;
/**
 @brief 获取字典型值配置，默认nil
 @param key key
 */
- (NSDictionary *)s_dictionaryValueForKey:(BDPSettingsKey *)key;

@end

NS_ASSUME_NONNULL_END
