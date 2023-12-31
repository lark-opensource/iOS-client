//
//  IESGurdClearCacheManager.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdClearCacheManager : NSObject

+ (instancetype)sharedManager;

/**
 * @brief 清除cache
 */
+ (void)clearCache;

+ (void)clearCacheExceptWhitelist;

/**
 根据accessKey和channel清理对应的缓存;
 */
+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel;

/**
根据accessKey和channel清理对应的缓存;
*/
+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                    completion:(void (^ _Nullable)(BOOL succeed, NSDictionary *info, NSError *error))completion;

+ (void)clearCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                        isSync:(BOOL)isSync
                    completion:(void (^ _Nullable)(BOOL succeed, NSDictionary *info, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
