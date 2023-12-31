//
//  ECOConfigService.h
//  ECOInfra
//
//  Created by  窦坚 on 2021/6/9.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Config 对外接口
@protocol ECOConfigService

/// 同步 - 根据 key 获取当前配置数据 Array type

- (nullable NSArray *)getArrayValueForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("Will be removed, using LarkSetting API to instead of") NS_SWIFT_NAME(getArrayValue(for:));

/// 同步 - 根据 key 获取当前配置数据 Dictionary type
- (nullable NSDictionary<NSString *, id> *)getDictionaryValueForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("Will be removed, using LarkSetting API to instead of") NS_SWIFT_NAME(getDictionaryValue(for:));

/// 同步 - 根据 key 获取当前配置数据 String type
- (nullable NSString *)getStringValueForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("Will be removed, using LarkSetting API to instead of") NS_SWIFT_NAME(getStringValue(for:));

/// 同步 - 根据 key 获取当前配置数据 BOOL type
- (BOOL)getBoolValueForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("Will be removed, using LarkSetting API to instead of")DEPRECATED_MSG_ATTRIBUTE("Will be removed, using LarkSetting API to instead of")  NS_SWIFT_NAME(getBoolValue(for:));

/// 同步 - 根据 key 获取当前配置数据 Int type
- (int)getIntValueForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("Will be removed, using LarkSetting API to instead of") NS_SWIFT_NAME(getIntValue(for:));

/// 同步 - 根据 key 获取当前配置数据 double type
- (double)getDoubleValueForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("Will be removed, using LarkSetting API to instead of") NS_SWIFT_NAME(getDoubleValue(for:));

/// 同步 - 根据 key 获取当前最新的配置数据 Array type *（*
- (nullable NSArray *)getLatestArrayValueForKey:(NSString *)key NS_SWIFT_NAME(getLatestArrayValue(for:));

/// 同步 - 根据 key 获取当前最新的配置数据 Dictionary type
- (nullable NSDictionary<NSString *, id> *)getLatestDictionaryValueForKey:(NSString *)key NS_SWIFT_NAME(getLatestDictionaryValue(for:));
@end

NS_ASSUME_NONNULL_END
