//
//  EffectPlatformCache.h
//  EffectPlatformSDK
//
//  Created by 琨王 on 2019/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@class IESEffectPlatformResponseModel;
@class IESEffectPlatformNewResponseModel;

@protocol EffectPlatformCacheService <NSObject>

- (nullable IESEffectModel *)effectWithKey:(NSString *)key;
- (nullable IESEffectPlatformResponseModel *)objectWithKey:(NSString *)key;
- (nullable IESEffectPlatformNewResponseModel *)newResponseWithKey:(NSString *)key;

- (void)setEnableMemoryCache:(BOOL)enable;

- (void)clearMemory;

- (void)clear;

- (void)clearJsonAndObjectForKey:(NSString *)key;

- (void)setJson:(NSDictionary *)json
         object:(IESEffectPlatformResponseModel *)object
         forKey:(NSString *)key;

- (void)setJson:(NSDictionary *)json
    newResponse:(IESEffectPlatformNewResponseModel *)object
         forKey:(NSString *)key;

- (void)setJson:(NSDictionary *)json
         effect:(IESEffectModel *)object
         forKey:(NSString *)key;

- (nullable NSDictionary *)modelDictWithKey:(NSString *)key;

- (void)setJson:(NSDictionary *)json
         forKey:(NSString *)key;

@end

@interface EffectPlatformCache : NSObject<EffectPlatformCacheService>
- (instancetype)initWithAccessKey:(NSString *)accessKey;
@end

NS_ASSUME_NONNULL_END
