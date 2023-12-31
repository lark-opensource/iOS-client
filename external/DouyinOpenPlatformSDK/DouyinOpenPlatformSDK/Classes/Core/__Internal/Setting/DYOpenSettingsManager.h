//
//  DYOpenSettingsManager.h
//  Pods
//
//  Created by bytedance on 2022/6/24.
//

#import <Foundation/Foundation.h>

@interface DYOpenSettingsManager: NSObject

@property (atomic, readonly) NSInteger lastSettingsTime;

@property (atomic, copy, readonly, nullable) NSDictionary *vidInfo;

+ (instancetype _Nonnull)sharedManager;
 
- (void)requestSettings;

/**
 @brief Get boolean value configuration, default NO
 @param key key
 */
- (BOOL)s_boolValueForKey:(NSString *_Nonnull)key;
/**
 @brief 获取整型值配置，默认0
 @param key key
 */
- (NSInteger)s_integerValueForKey:(NSString *_Nonnull)key;
/**
 @brief 获取整型值配置，没有返回默认值
 @param key key
 */
- (NSInteger)s_integerValueForKey:(NSString *_Nonnull)key defaultInteger:(NSInteger)defaultInteger;
/**
 @brief Get interger value configuration, default 0
 @param key key
 */
- (float)s_floatValueForKey:(NSString *_Nonnull)key;
/**
 @brief Get string value configuration, default nil
 @param key key
 */
- (NSString *_Nullable)s_stringValueForKey:(NSString *_Nonnull)key;
/**
 @brief Get array value configuration, default nil
 @param key key
 */
- (NSArray *_Nullable)s_arrayValueForKey:(NSString *_Nonnull)key;
/**
 @brief Get dictionary value configuration, default nil
 @param key key
 */
- (NSDictionary *_Nullable)s_dictionaryValueForKey:(NSString *_Nonnull)key;

/**
 @brief Get object value configuration, default nil
 @param key key
 */
- (id _Nullable)s_objectValueForKey:(NSString *_Nonnull)key;

@end
