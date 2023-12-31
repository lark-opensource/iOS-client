//
//  ECOConfig.h
//  EEMicroAppSDK
//
//  Created by Meng on 2021/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ECOConfig : NSObject

- (instancetype)initWithConfigID:(NSString *)configID;

- (void)updateConfigData:(NSDictionary<NSString *, id> *)configData;

/// 根据 key 获取当前配置数据 Array type
- (nullable NSArray *)getArrayValueForKey:(NSString *)key NS_SWIFT_NAME(getArrayValue(for:));

/// 根据 key 获取当前配置数据 Dictionary type
- (nullable NSDictionary<NSString *, id> *)getDictionaryValueForKey:(NSString *)key NS_SWIFT_NAME(getDictionaryValue(for:));

/// 根据 key 获取当前配置数据 String type
- (nullable NSString *)getStringValueForKey:(NSString *)key NS_SWIFT_NAME(getStringValue(for:));

/// 根据 key 获取当前配置数据 BOOL type
- (BOOL)getBoolValueForKey:(NSString *)key NS_SWIFT_NAME(getBoolValue(for:));

/// 根据 key 获取当前配置数据 Int type
- (int)getIntValueForKey:(NSString *)key NS_SWIFT_NAME(getIntValue(for:));

/// 根据 key 获取当前配置数据 double type
- (double)getDoubleValueForKey:(NSString *)key NS_SWIFT_NAME(getDoubleValue(for:));

/// 根据 key 获取当前配置数据序列化为 string 后的值
- (nullable NSString *)getSerializedStringValueForKey:(NSString *)key NS_SWIFT_NAME(getSerializedStringValue(for:));

/// 同步 - 根据 key 获取当前最新的配置数据 Array type *（*
- (nullable NSArray *)getLatestArrayValueForKey:(NSString *)key NS_SWIFT_NAME(getLatestArrayValue(for:));

/// 同步 - 根据 key 获取当前最新的配置数据 Dictionary type
- (nullable NSDictionary<NSString *, id> *)getLatestDictionaryValueForKey:(NSString *)key NS_SWIFT_NAME(getLatestDictionaryValue(for:));
@end

NS_ASSUME_NONNULL_END
