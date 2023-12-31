//
//  NSDictionary+IESGurdKit.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (IESGurdKit)

- (BOOL)iesgurdkit_safeBoolWithKey:(NSString *)key defaultValue:(BOOL)defaultValue;

- (NSInteger)iesgurdkit_safeIntegerWithKey:(NSString *)key defaultValue:(NSInteger)defaultValue;

- (NSString *)iesgurdkit_safeStringWithKey:(NSString *)key;

- (NSArray *)iesgurdkit_safeArrayWithKey:(NSString *)key itemClass:(Class)itemClass;

- (NSDictionary *)iesgurdkit_safeDictionaryWithKey:(NSString *)key
                                          keyClass:(Class)keyClass
                                        valueClass:(Class)valueClass;

@end

NS_ASSUME_NONNULL_END
